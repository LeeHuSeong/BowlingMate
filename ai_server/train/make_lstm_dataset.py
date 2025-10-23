import os
import sys
import numpy as np

# 상위 디렉터리 추가
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) 
from service.dtw_service import compare_poses, compute_diff_sequence
from scipy.interpolate import interp1d

#경로 설정
BASE_PATH = os.path.dirname(os.path.abspath(__file__))
KEYPOINT_DIR = os.path.join(BASE_PATH, "..", "data", "keypoints_norm")
OUTPUT_DIR = os.path.join(BASE_PATH, "..", "data", "lstm_dataset")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 구질 목록
PITCH_TYPES = ["twohand", "stroker", "cranker", "thumbless"]

# 프레임별 라벨 기준
FRAME_THRESHOLD = 0.1   # 프레임별 diff 임계값
SEQUENCE_RATIO_THRESHOLD = 0.2  # 비정상 프레임 비율 ≥ 20% → 비정상 시퀀스로 간주


#데이터 증강 함수
def jitter_sequence(seq, std=0.015):
    noise = np.random.normal(0, std, seq.shape)
    return seq + noise

def time_warp_sequence(seq, factor):
    from scipy.interpolate import interp1d
    t = np.linspace(0, 1, len(seq))
    t_new = np.linspace(0, 1, int(len(seq) * factor))
    interpolator = interp1d(t, seq, axis=0, kind='linear', fill_value='extrapolate')
    return interpolator(t_new)

def save_augmented(diff_seq, is_wrong, base_name, suffix, output_dir):
    label_seq = np.ones((diff_seq.shape[0], 1)) if is_wrong else np.zeros((diff_seq.shape[0], 1))
    np.save(os.path.join(output_dir, f"{base_name}_{suffix}_diff.npy"), diff_seq)
    np.save(os.path.join(output_dir, f"{base_name}_{suffix}_label.npy"), label_seq)
    print(f"증강 저장: {base_name}_{suffix} (shape: {diff_seq.shape})")


# 구질별 데이터셋 생성 루프
for pitch in PITCH_TYPES:
    ref_path = os.path.join(KEYPOINT_DIR, pitch, f"{pitch}_001.npy")
    if not os.path.exists(ref_path):
        print(f"기준 파일 없음: {ref_path} (스킵)")
        continue

    pitch_output_dir = os.path.join(OUTPUT_DIR, pitch)
    os.makedirs(pitch_output_dir, exist_ok=True)

    pitch_dir = os.path.join(KEYPOINT_DIR, pitch)
    files = [f for f in os.listdir(pitch_dir) if f.endswith(".npy")]

    print(f"[{pitch}] 총 {len(files)}개 파일 처리 시작")

    for filename in files:
        file_path = os.path.join(pitch_dir, filename)
        if file_path == ref_path:
            continue

        try:
            print(f"처리 중: {filename}")
            distance, ref, test, path = compare_poses(ref_path, file_path)
            diff_seq = compute_diff_sequence(ref, test, path)  # shape: (T, 34)


            # 프레임 단위 라벨링
            frame_diffs = np.mean(np.abs(diff_seq), axis=1)  # 각 프레임별 평균 diff
            label_seq = (frame_diffs >= FRAME_THRESHOLD).astype(int).reshape(-1, 1)


            # 시퀀스 전체 중 20% 이상이 비정상이면 “비정상 시퀀스”
            abnormal_ratio = np.mean(label_seq)
            is_wrong = abnormal_ratio >= SEQUENCE_RATIO_THRESHOLD

            base_name = filename.replace(".npy", "")


            # 저장
            np.save(os.path.join(pitch_output_dir, f"{base_name}_diff.npy"), diff_seq)
            np.save(os.path.join(pitch_output_dir, f"{base_name}_label.npy"), label_seq)

            # ---------------------
            # 데이터 증강 (라벨 유지)
            # ---------------------
            save_augmented(jitter_sequence(diff_seq), is_wrong, base_name, "jitter", pitch_output_dir)
            save_augmented(time_warp_sequence(diff_seq, 1.1), is_wrong, base_name, "stretch", pitch_output_dir)
            save_augmented(time_warp_sequence(diff_seq, 0.9), is_wrong, base_name, "compress", pitch_output_dir)

            print(f"저장 완료: {pitch}/{base_name} | 비정상 비율={abnormal_ratio:.2f} | 전체={len(label_seq)}프레임")

        except Exception as e:
            print(f"실패: {filename} → {e}")

print("모든 구질의 LSTM 학습용 diff/label 데이터셋 생성 완료.")
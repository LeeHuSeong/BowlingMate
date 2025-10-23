import numpy as np
import cv2
import subprocess
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from multiprocessing import Pool, cpu_count

JOINT_FEEDBACK_MAP = {
    0: "머리 위치가 흔들리고 있습니다.",
    1: "왼쪽 어깨의 움직임을 안정시켜야 합니다.",
    2: "오른쪽 어깨의 움직임을 안정시켜야 합니다.",
    3: "왼쪽 팔꿈치를 더 고정할 필요가 있습니다.",
    4: "오른쪽 팔꿈치를 더 고정할 필요가 있습니다.",
    5: "왼팔의 움직임이 불안정합니다.",
    6: "오른팔의 움직임이 불안정합니다.",
    7: "왼쪽 손목이 많이 흔들립니다.",
    8: "오른쪽 손목이 많이 흔들립니다.",
    9: "왼손의 흔들림이 큽니다.",
    10: "오른손의 흔들림이 큽니다.",
    11: "왼쪽 엉덩이의 움직임을 안정시켜야 합니다.",
    12: "오른쪽 엉덩이의 흔들림이 큽니다.",
    13: "왼무릎을 고정해서 안정적인 자세를 유지하세요.",
    14: "오른무릎의 위치를 일정하게 유지하세요.",
    15: "왼발의 흔들림이 큽니다.",
    16: "오른발의 흔들림을 줄이세요."
}

#FFmpeg 변환 (코덱 호환성용)
def convert_video_with_ffmpeg(input_path, output_path):
    command = [
        'ffmpeg', '-y',
        '-i', input_path,
        '-vcodec', 'libx264',
        '-pix_fmt', 'yuv420p',
        '-vf', "scale='trunc(iw/2)*2:trunc(ih/2)*2'",
        output_path
    ]
    try:
        subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"ffmpeg 변환 완료: {output_path}")
    except subprocess.CalledProcessError as e:
        print(f"ffmpeg 변환 실패: {e}")

#관절 회전 (아이폰 영상이 세로여서 필요)
def rotate_keypoints_90ccw(keypoints):
    return [(y, x, c) for (x, y, c) in keypoints]


#프레임 단위 시각화
def render_frame(args):
    i, frame, raw_kp, norm_kp, label, diff, top_joints, pose_pairs, h, w, pad = args

    # 캔버스 초기화
    canvas = np.full((h + pad * 2, w, 3), 255, dtype=np.uint8)
    canvas[pad:pad + h, 0:w] = frame

    # 현재 프레임 diff 계산
    diff = diff.reshape(17, 2)
    mags = np.linalg.norm(diff, axis=1)  # 각 관절별 차이 크기
    max_mag = np.max(mags) if np.max(mags) > 0 else 1.0
    norm_mags = mags / max_mag  # 0~1 정규화

    # 임계값 설정 (차이 크기 0.15 이상이면 빨강)
    threshold = 0.22

    # 관절쌍 단위로 색상 계산
    for a, b in pose_pairs:
        x1, y1, c1 = raw_kp[a]
        x2, y2, c2 = raw_kp[b]
        if c1 < 0.3 or c2 < 0.3:
            continue

        # 두 관절 차이 평균으로 판단
        joint_diff = (norm_mags[a] + norm_mags[b]) / 2.0
        is_abnormal = joint_diff > threshold

        color = (0, 0, 255) if is_abnormal else (0, 255, 0)
        thickness = 4 if is_abnormal else 2

        x1, y1 = int(x1 * w), int(y1 * h) + pad
        x2, y2 = int(x2 * w), int(y2 * h) + pad
        cv2.line(canvas, (x1, y1), (x2, y2), color, thickness)

    # 상위 오차 관절 강조 표시 (빨강 점)
    for j in top_joints:
        if j < len(raw_kp):
            x, y, c = raw_kp[j]
            if c > 0.3:
                px, py = int(x * w), int(y * h) + pad
                cv2.circle(canvas, (px, py), 6, (0, 0, 255), -1)

    return canvas


#전체 시각화 실행 함수
def visualize_pose_feedback(raw_keypoints, norm_keypoints, labels, diff_seq, top_joints, save_path, source_video):
    cap = cv2.VideoCapture(source_video)
    fps = cap.get(cv2.CAP_PROP_FPS)
    ret, first_frame = cap.read()
    if not ret:
        print("첫 프레임 읽기 실패")
        return

    # 영상 방향 감지
    if first_frame.shape[1] > first_frame.shape[0]:
        first_frame = cv2.rotate(first_frame, cv2.ROTATE_90_CLOCKWISE)
        rotated = True
    else:
        rotated = False

    h, w = first_frame.shape[:2]
    pad = 40
    output_size = (w, h + pad * 2)

    temp_path = save_path.replace(".mp4", "_temp.mp4")
    out = cv2.VideoWriter(temp_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, output_size)

    # 관절 연결 정의
    pose_pairs = [
        (0, 1), (1, 3), (0, 2), (2, 4),
        (5, 7), (7, 9), (6, 8), (8, 10),
        (5, 6), (5, 11), (6, 12),
        (11, 12), (11, 13), (13, 15),
        (12, 14), (14, 16)
    ]

    # 프레임 수 안전 보정
    frames = []
    for _ in range(min(len(norm_keypoints), len(labels))):
        ret, frame = cap.read()
        if not ret:
            break
        if rotated:
            frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
        frames.append(frame)
    cap.release()

    safe_len = min(len(frames), len(raw_keypoints), len(norm_keypoints), len(labels), len(diff_seq))
    args = [
        (i, frames[i], rotate_keypoints_90ccw(raw_keypoints[i]), norm_keypoints[i],
         labels[i], diff_seq[i], top_joints, pose_pairs, h, w, pad)
        for i in range(safe_len)
    ]

    print(f"병렬 렌더링 시작 ({len(args)} frames)...")
    with Pool(processes=min(cpu_count(), 4)) as pool:
        results = pool.map(render_frame, args)

    for canvas in results:
        out.write(canvas)
    out.release()

    convert_video_with_ffmpeg(temp_path, save_path)
    if os.path.exists(temp_path):
        os.remove(temp_path)
    print(f"시각화 완료: {save_path}")


#이상 관절 정리 함수
def summarize_top_joints(diff_seq, labels, top_k=4):
    joint_error_sum = np.zeros(17)
    safe_len = min(len(diff_seq), len(labels))

    for i in range(safe_len):
        if labels[i] == 1:
            diffs = diff_seq[i].reshape(17, 2)
            mags = np.linalg.norm(diffs, axis=1)
            joint_error_sum += mags * (mags > 0.1)

    sorted_idx = np.argsort(joint_error_sum)[::-1]
    return [int(j) for j in sorted_idx[:top_k] if joint_error_sum[j] > 0]
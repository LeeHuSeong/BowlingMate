import sys, os
from glob import glob
from movenet_train import extract_keypoints_for_training

# 경로 설정
BASE_PATH = os.path.dirname(os.path.abspath(__file__))
LEARNING_DIR = os.path.join(BASE_PATH, "..", "data", "Learning")
OUTPUT_DIR = os.path.join(BASE_PATH, "..", "data", "keypoints_norm")

os.makedirs(OUTPUT_DIR, exist_ok=True)

# 영상 파일 목록 필터링
video_files = glob(os.path.join(LEARNING_DIR, "*", "*"))
video_files = [vf for vf in video_files if vf.lower().endswith(('.mov', '.mp4', '.avi', '.mkv'))]
print(f"총 {len(video_files)}개 학습용 영상 탐색 완료")

# MoveNet 기반 키포인트 추출 실행
for video_path in video_files:
    try:
        extract_keypoints_for_training(video_path, OUTPUT_DIR)
    except Exception as e:
        print(f"오류 발생: {video_path} → {e}")

print("모든 학습용 영상의 keypoints_norm 추출 완료.")
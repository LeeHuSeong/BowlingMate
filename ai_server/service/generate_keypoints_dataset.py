import sys, os
from glob import glob
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from service.movenet_service import extract_keypoints_from_video

#경로 설정
BASE_PATH = os.path.dirname(os.path.abspath(__file__))
LEARNING_DIR = os.path.join(BASE_PATH, "..", "data", "Learning")
OUTPUT_DIR = os.path.join(BASE_PATH, "..", "data", "keypoints")


#.MOV 등 확장자 필터링
video_files = glob(os.path.join(LEARNING_DIR, "*", "*"))
video_files = [vf for vf in video_files if vf.lower().endswith(('.mov', '.mp4', '.avi', '.mkv'))]
print(f"총 {len(video_files)}개 영상 탐색")


#MoveNet 기반 키포인트 추출
for video_path in video_files:
    try:
        extract_keypoints_from_video(video_path, OUTPUT_DIR)
    except Exception as e:
        print(f"오류 발생: {video_path} → {e}")


print("모든 영상의 키포인트 추출 완료.")
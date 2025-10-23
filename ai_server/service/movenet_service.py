#Movenet.py
import numpy as np
import tensorflow as tf
import cv2
import os

# GPU 설정
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        print(f"GPU 사용 설정 완료: {len(gpus)}개 GPU 감지됨")
    except RuntimeError as e:
        print(f"GPU 설정 오류: {e}")
else:
    print("GPU 사용 불가. CPU로 실행됩니다.")

# MoveNet Thunder 모델 로드
MODEL_PATH = os.path.join("model", "movenet_thunder")

print(f"MoveNet Thunder 모델 로딩 중... ({MODEL_PATH})")
movenet = tf.saved_model.load(MODEL_PATH)
movenet_fn = movenet.signatures['serving_default']
print("MoveNet 모델 로드 완료 (GPU 사용 가능)")


#키 포인트 추출
def detect_pose(image):
    input_image = tf.image.resize_with_pad(image, 256, 256)
    input_image = tf.expand_dims(input_image, axis=0)
    input_image = tf.cast(input_image, dtype=tf.int32)
    outputs = movenet_fn(input_image)
    keypoints = outputs['output_0'].numpy()[0, 0, :, :]  # (17, 3)
    return keypoints

# 가로 영상일 경우 세로로 회전
def rotate_frame_if_needed(frame):  # 수정
    h, w = frame.shape[:2]
    if w > h:
        return cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
    return frame

# 관절 정규화
def normalize_keypoints(keypoints):
    """
    관절 좌표를 Torso(어깨~엉덩이 중심) 기준으로 정규화합니다.
    입력: keypoints (17, 3)
    출력: normalized_keypoints (17, 3)
    """
    keypoints = np.array(keypoints)
    if keypoints.shape != (17, 3):
        return keypoints  # 잘못된 입력 보호

    # 중심 계산
    shoulder_center = (keypoints[5][:2] + keypoints[6][:2]) / 2
    hip_center = (keypoints[11][:2] + keypoints[12][:2]) / 2

    # 기준 길이: torso
    torso_length = np.linalg.norm(shoulder_center - hip_center)
    if torso_length < 1e-5:  # division by zero 방지
        torso_length = 1.0

    # 정규화 (hip 기준으로 이동, torso 길이로 나눔)
    normalized_xy = (keypoints[:, :2] - hip_center) / torso_length

    # confidence는 그대로 유지
    normalized = np.hstack([normalized_xy, keypoints[:, 2:3]])
    return normalized

#keyPoint 관절 추출
def extract_keypoints_from_video(video_path, output_folder):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"영상 열기 실패: {video_path}")
        return None, None

    raw_keypoints = []
    norm_keypoints = []
    frame_count = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame = rotate_frame_if_needed(frame)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame_tensor = tf.convert_to_tensor(frame_rgb)

        try:
            keypoints = detect_pose(frame_tensor)
            normalized = normalize_keypoints(keypoints)
            raw_keypoints.append(keypoints)
            norm_keypoints.append(normalized)
        except Exception as e:
            print(f"키포인트 추출 오류 (프레임 {frame_count}): {e}")

        frame_count += 1
        if frame_count % 10 == 0:
            print(f"{frame_count}프레임 처리 중...")

    cap.release()

    if len(norm_keypoints) == 0:
        print(f"{video_path} 처리 실패: 키포인트 없음")
        return None, None

    print(f"추출 완료: 총 {len(norm_keypoints)}프레임")
    return np.array(raw_keypoints), np.array(norm_keypoints)

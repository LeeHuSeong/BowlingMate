import os
import glob
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
import cv2


movenet = hub.load("https://tfhub.dev/google/movenet/singlepose/thunder/4").signatures['serving_default']


# GPU 메모리 제어
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


#경로 설정
MODEL_PATH = os.path.join("model", "movenet_thunder")

print(f"MoveNet Thunder 모델 로딩 중... ({MODEL_PATH})")
movenet = tf.saved_model.load(MODEL_PATH)
movenet_fn = movenet.signatures['serving_default']
print("MoveNet 모델 로드 완료 (GPU 사용 가능)")
# 포즈 추출
def detect_pose(image):
    """입력 이미지에서 keypoints (17,3) 추출"""
    input_image = tf.image.resize_with_pad(image, 256, 256)
    input_image = tf.expand_dims(input_image, axis=0)
    input_image = tf.cast(input_image, dtype=tf.int32)
    outputs = movenet_fn(input_image)
    keypoints = outputs['output_0'].numpy()[0, 0, :, :]  # (17,3)
    return keypoints


# 정규화 함수 (Torso 기준)
def normalize_keypoints(keypoints):
    """
    관절 좌표를 Torso(어깨~엉덩이 중심) 기준으로 정규화합니다.
    입력: keypoints (17, 3)
    출력: normalized_keypoints (17, 3)
    """
    keypoints = np.array(keypoints)
    if keypoints.shape != (17, 3):
        return keypoints

    shoulder_center = (keypoints[5][:2] + keypoints[6][:2]) / 2
    hip_center = (keypoints[11][:2] + keypoints[12][:2]) / 2
    torso_length = np.linalg.norm(shoulder_center - hip_center)
    if torso_length < 1e-5:
        torso_length = 1.0

    normalized_xy = (keypoints[:, :2] - hip_center) / torso_length
    normalized = np.hstack([normalized_xy, keypoints[:, 2:3]])
    return normalized


def detect_video_orientation(frame):
    """프레임의 가로/세로 비율로 orientation 감지"""
    h, w, _ = frame.shape
    if h > w:
        return "portrait"
    else:
        return "landscape"

def rotate_keypoints_90ccw(keypoints):
    """정규화 좌표 기준 반시계 90도 회전"""
    return [(y, 1 - x, c) for (x, y, c) in keypoints]


# 학습용 keypoints 추출 함수
def extract_keypoints_for_training(video_path, output_folder):
    """
    학습용 영상에서 keypoints_norm만 추출하여 .npy로 저장
    """
    video_name = os.path.splitext(os.path.basename(video_path))[0]
    label = video_name.split("_")[0]
    class_folder = os.path.join(output_folder, label)
    os.makedirs(class_folder, exist_ok=True)
    output_path = os.path.join(class_folder, f"{video_name}.npy")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"영상 열기 실패: {video_path}")
        return None

    all_keypoints = []
    frame_count = 0
    orientation_checked = False
    rotation_needed = False

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1
        if frame_count % 10 == 0:
            print(f"{video_name} 프레임 {frame_count} 처리 중...")

        # 회전 방향 감지 (처음 1회만)
        if not orientation_checked:
            orientation = detect_video_orientation(frame)
            if orientation == "portrait":
                print(f"[INFO] 세로 영상 감지됨 → 90° 반시계 회전 적용: {video_name}")
                rotation_needed = True
            orientation_checked = True

        # 세로 영상일 경우 프레임 회전
        if rotation_needed:
            frame = cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)

        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image_tensor = tf.convert_to_tensor(image_rgb)

        try:
            keypoints = detect_pose(image_tensor)
            normalized = normalize_keypoints(keypoints)
            # 세로 영상이면 keypoints도 좌표계 반시계 회전
            if rotation_needed:
                normalized = np.array(rotate_keypoints_90ccw(normalized))
            all_keypoints.append(normalized)
        except Exception as e:
            print(f"키포인트 추출 오류 (프레임 {frame_count}): {e}")

    cap.release()

    if len(all_keypoints) == 0:
        print(f"{video_name} 처리 실패: 키포인트 없음")
        return None

    all_keypoints = np.array(all_keypoints)
    np.save(output_path, all_keypoints)
    print(f"저장 완료: {output_path} (shape: {all_keypoints.shape})")

    return output_path
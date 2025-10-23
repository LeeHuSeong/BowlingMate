# DTW.py
import math
import numpy as np
from scipy.spatial.distance import euclidean
from fastdtw import fastdtw


def load_keypoints(file_path):
    return np.load(file_path)


def compare_poses(reference_path, test_keypoints):
    """
    reference_path: 기준 자세 .npy 파일 경로 (str)
    test_keypoints: 비교 대상 (numpy 배열 or .npy 경로)
    """
    ref = load_keypoints(reference_path)

    # test_keypoints가 str일 경우 np.load로 불러오기
    if isinstance(test_keypoints, str):
        test = load_keypoints(test_keypoints)
    else:
        test = np.array(test_keypoints, dtype=np.float32)

    # keypoints가 3D numpy 배열(프레임 × 17 × 3)인지 확인
    if ref.ndim != 3 or test.ndim != 3:
        raise ValueError(f"잘못된 keypoints 형태입니다: ref={ref.shape}, test={test.shape}")

    # 각 프레임별 (17,2) → (34,) flatten
    ref_seq = [kp[:, :2].flatten() for kp in ref]
    test_seq = [kp[:, :2].flatten() for kp in test]

    # FastDTW 실행
    distance, path = fastdtw(ref_seq, test_seq, dist=euclidean)
    print(f"DTW 거리: {distance:.2f}")

    return distance, ref, test, path


def compute_diff_sequence(ref, test, path):
    ref_seq = [r[:, :2].flatten() for r in ref]
    test_seq = [t[:, :2].flatten() for t in test]
    diff_seq = [test_seq[j] - ref_seq[i] for i, j in path]
    return np.array(diff_seq)


def compute_dtw_score(distance):
    if distance <= 0:
        return 100.0
    score = 100 / (1 + math.log1p(distance) / 5)
    return round(score, 2)

#compare_poses() + DTW 점수 계산 버전
def compare_poses_with_score(reference_path, norm_keypoints):
    distance, ref, test, path = compare_poses(reference_path, norm_keypoints)
    dtw_score = compute_dtw_score(distance)
    return dtw_score, distance, ref, test, path
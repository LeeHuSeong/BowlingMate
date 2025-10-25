import cv2
import shutil

from flask import Blueprint, request, jsonify
from service.movenet_service import extract_keypoints_from_video
from service.dtw_service import compare_poses_with_score, compute_diff_sequence
from service.lstm_service import predict_framewise_labels
from service.visualize_service import visualize_pose_feedback, summarize_top_joints

import os, uuid

analyze_bp = Blueprint('analyze', __name__)

@analyze_bp.route('/analyze_pose', methods=['POST'])
def analyze_pose():
    try:
        #요청 검증
        if 'video' not in request.files:
            return jsonify({'error': '영상 파일이 없습니다.'}), 400

        file = request.files['video']
        pitch_type = request.form.get('pitch_type')
        uid = request.form.get('uid')
        start_frame = int(request.form.get('start_frame', 0))
        end_frame = int(request.form.get('end_frame', -1))

        if not pitch_type:
            return jsonify({'error': 'pitch_type 누락'}), 400

        
        #1. 업로드 파일 저장
        upload_dir = f"output/upload/{uid}"
        os.makedirs(upload_dir, exist_ok=True)
        filename = file.filename
        video_path = os.path.join(upload_dir, file.filename)
        file.save(video_path)
        print(f"영상 저장 완료: {video_path}")

        #2. 영상 자르기
        cropped_dir = f"output/cropped/{uid}"
        os.makedirs(cropped_dir, exist_ok=True)
        cropped_path = os.path.join(cropped_dir, f"cropped_{uuid.uuid4().hex}.mp4")

        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        if end_frame == -1 or end_frame > total_frames:
            end_frame = total_frames

        out = cv2.VideoWriter(cropped_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, (width, height))

        current = 0
        while True:
            ret, frame = cap.read()
            if not ret or current > end_frame:
                break
            if current >= start_frame:
                out.write(frame)
            current += 1
        cap.release()
        out.release()
        print(f"[CROPPED] {cropped_path} ({start_frame}~{end_frame})")

        #3. MoveNet 키포인트 추출
        keypoint_dir = f"output/keypoints/{uid}"
        os.makedirs(keypoint_dir, exist_ok=True)
        raw_keypoints, norm_keypoints = extract_keypoints_from_video(video_path, keypoint_dir)

        if raw_keypoints is None or norm_keypoints is None:
            return jsonify({'error': '키포인트 추출 실패'}), 500

        #구질 설정
        type_map = {
            '스트로커': 'stroker',
            '투핸드': 'twohand',
            '덤리스': 'thumbless',
            '크랭커': 'cranker'
        }
        mapped_type = type_map.get(pitch_type.strip(), pitch_type.strip())

        reference_path = f"data/keypoints_norm/{mapped_type}/{mapped_type}_001.npy"
        model_path = f"model/lstm_{mapped_type}.h5"


        #4. DTW 비교 및 diff 계산
        dtw_score, distance, ref, test, path = compare_poses_with_score(reference_path, norm_keypoints)
        diff_seq = compute_diff_sequence(ref, test, path)
        labels, confidence = predict_framewise_labels(diff_seq, model_path)
        lstm_score = round(confidence * 100, 2)
        top_joints = summarize_top_joints(diff_seq, labels, 4)

        #이상 프레임 비율 계산
        wrong_ratio = sum(labels) / len(labels) if len(labels) > 0 else 0

        #관절별 피드백 문장 구성
        feedback_lines = []
        from service.visualize_service import JOINT_FEEDBACK_MAP
        for j in top_joints:
            if j in JOINT_FEEDBACK_MAP:
                feedback_lines.append(JOINT_FEEDBACK_MAP[j])

        # 점수 기반 총평 메시지 (조건 세분화)
        if lstm_score >= 90 and dtw_score >= 80 and wrong_ratio < 0.1:
            summary = "폼이 안정적이며 일관성이 높습니다."
        elif lstm_score >= 75:
            summary = "대체로 양호하나 일부 자세에서 불균형이 감지됩니다."
        else:
            summary = "자세 흔들림이 많고 교정이 필요합니다."

        #점수 기반 총평 메시지
        feedback_text = (
            f"**분석 요약**\n"
            f"LSTM 안정도: {lstm_score:.2f}점\n"
            f"DTW 유사도: {dtw_score:.2f}점\n\n"
            f"**총평:** {summary}\n\n"
        )

        if feedback_lines:
            feedback_text += "**개선이 필요한 부위:**\n- " + "\n- ".join(feedback_lines)
        else:
            feedback_text += "모든 관절이 안정적으로 유지되었습니다."

        #시각화 결과 저장(local)
        comparison_dir_local = f"output/comparison/{uid}"
        comparison_dir_shared = f"/app/shared/comparison/{uid}"  

        os.makedirs(comparison_dir_local, exist_ok=True)
        os.makedirs(comparison_dir_shared, exist_ok=True)

        comparison_name = f"comparison_{uuid.uuid4().hex}.mp4"
        comparison_path_local = os.path.join(comparison_dir_local, comparison_name)
        comparison_path_shared = os.path.join(comparison_dir_shared, comparison_name)

        visualize_pose_feedback(
            raw_keypoints=raw_keypoints,
            norm_keypoints=norm_keypoints,
            labels=labels,
            diff_seq=diff_seq,
            top_joints=top_joints,
            save_path=comparison_path_local,
            source_video=cropped_path
        )

        shutil.copyfile(comparison_path_local, comparison_path_shared)

        print(f"[SAVE] 시각화 완료: {comparison_path_local}")
        print(f"[SHARED] 복사 완료: {comparison_path_shared}")

        #결과 응답(local path)
        return jsonify({
            "uid": uid,
            "pitch_type": pitch_type,
            "range": [start_frame, end_frame],
            "dtw": {
                "distance": round(distance, 4),
                "score": dtw_score,
                "description": (
                    "기준 자세와의 유사도 (DTW distance는 낮을수록, score는 높을수록 좋음)"
                )
            },
            "lstm": {
                "score": lstm_score,
                "description": "AI가 예측한 LSTM 기반 프레임별 동작 안정도 (높을수록 좋음)"
            },
            "feedback": feedback_text,
            "comparison_video_path": comparison_path_shared
        })
    
    except Exception as e:
        print(f"분석 중 오류: {e}")
        return jsonify({'error': str(e)}), 500
    
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
import os

# 구질별 기대 입력 길이
EXPECTED_LEN = {
    "twohand": 310,
    "cranker": 375,
    "stroker": 268,
    "thumbless": 292
}

# 추론 함수
# LSTM 학습 모델을 로드하여 diff_seq를 프레임별로 예측
def predict_framewise_labels(diff_seq, model_path):
    # pitch_type 추출
    pitch_type = os.path.basename(model_path).replace("lstm_", "").replace(".h5", "")
    maxlen = EXPECTED_LEN.get(pitch_type, 278)

    # 입력 길이 확인
    input_len = len(diff_seq)
    print(f"[LSTM] pitch_type={pitch_type} | 입력 프레임={input_len} | 기대 프레임={maxlen}")

    # 너무 짧은 시퀀스 예외 처리
    if input_len < 200:
        raise ValueError("영상 길이가 너무 짧습니다. 전체 투구 동작이 포함되도록 촬영해주세요.")

    # 모델 로드
    model = load_model(model_path)

    # 길이 조정 (길면 자르고, 짧으면 패딩)
    if input_len > maxlen:
        diff_seq = diff_seq[:maxlen]
        print(f"[LSTM] 입력 시퀀스가 길어 {maxlen}프레임으로 자름 (원래 {input_len})")
    elif input_len < maxlen:
        diff_seq = pad_sequences([diff_seq], padding='post', maxlen=maxlen, dtype='float32')[0]
        print(f"[LSTM] 입력 시퀀스가 짧아 {maxlen}프레임까지 패딩함 (원래 {input_len})")
    else:
        print(f"[LSTM] 입력 시퀀스 길이 {maxlen}프레임 (패딩 불필요)")

    # 모델 입력 형태로 변환 (1, maxlen, feature_dim)
    padded = np.expand_dims(diff_seq, axis=0)

    # 예측
    preds = model.predict(padded)  # shape: (1, T, 1)
    framewise = np.squeeze(preds[0])

    # 단일 값일 경우 numpy array로 변환
    if framewise.ndim == 0:
        framewise = np.array([framewise])

    # 프레임별 라벨(0/1) 및 신뢰도 계산
    labels = (framewise > 0.5).astype(int).tolist()[:len(diff_seq)]
    confidence = float(np.mean(framewise[:len(diff_seq)]))

    print(f"[LSTM] 예측 완료 | pitch_type={pitch_type} | frames={len(labels)} | conf={confidence:.2f}")
    return labels, confidence

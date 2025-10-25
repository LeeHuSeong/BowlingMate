# Python 기반 이미지
FROM python:3.9-slim

# 작업 디렉토리 지정
WORKDIR /app

# OpenCV용 시스템 의존 패키지 설치
RUN apt-get update && \
    apt-get install -y libgl1 libglib2.0-0 ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir tensorflow==2.10.0 keras==2.10.0 numpy==1.23.5 \
    opencv-python fastdtw scipy matplotlib scikit-learn flask

# 프로젝트 전체 복사 (model 포함)
COPY . .


# 필수 폴더 미리 생성 (없으면 에러 방지)
RUN mkdir -p model && mkdir -p output && mkdir -p data

# Flask 포트
EXPOSE 5000

# Flask 실행
CMD ["python", "app.py"]

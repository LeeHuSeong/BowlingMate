from flask import Flask
from route.analyze_route import analyze_bp
from route.video_route import video_bp
import os

app = Flask(__name__)

# 출력 폴더 생성
os.makedirs("output/upload", exist_ok=True)
os.makedirs("output/comparison", exist_ok=True)

# 라우트 등록
app.register_blueprint(analyze_bp)
app.register_blueprint(video_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
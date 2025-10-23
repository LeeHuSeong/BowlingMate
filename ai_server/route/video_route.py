from flask import Blueprint, send_file, jsonify
import os

video_bp = Blueprint('video', __name__)

@video_bp.route('/video/<filename>')
def serve_video(filename):
    path = os.path.join('output/comparison', filename)
    if not os.path.exists(path):
        return jsonify({'error': '비교 영상이 존재하지 않습니다.'}), 404
    return send_file(path, mimetype='video/mp4', as_attachment=False)
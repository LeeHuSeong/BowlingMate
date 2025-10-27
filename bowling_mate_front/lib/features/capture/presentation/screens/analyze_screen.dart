import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/preferences_helper.dart';

class AnalyzeScreen extends StatefulWidget {
  final String style;
  final String videoPath;
  final double startTime;
  final double endTime;

  const AnalyzeScreen({
    super.key,
    required this.style,
    required this.videoPath,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _sendAnalyzeRequest();
  }

  Future<void> _sendAnalyzeRequest() async {
    try {
      final uid = await PreferencesHelper.getUid();
      final token = await PreferencesHelper.getJwt();
      if (uid == null || token == null) {
        setState(() => _error = "로그인 정보가 없습니다.");
        return;
      }

      final formData = FormData.fromMap({
        "video": await MultipartFile.fromFile(widget.videoPath),
        "uid": uid,
        "pitch_type": widget.style.toLowerCase(),
        "range": [widget.startTime, widget.endTime],
      });

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "multipart/form-data",
        },
      ));

      final response = await dio.post("/api/analyze", data: formData);

      setState(() {
        _result = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            '오류 발생: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        )
            : _result != null
            ? _buildResultView(_result!)
            : const Center(child: Text('결과가 없습니다.')),
      ),
    );
  }

  Widget _buildResultView(Map<String, dynamic> result) {
    final dtw = result['dtw'] ?? {};
    final lstm = result['lstm'] ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('구질: ${result['pitch_type'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('분석 시각: ${result['created_at'] ?? '-'}'),
          const Divider(height: 30),

          Text('DTW 분석', style: _sectionTitle()),
          Text(' - 거리값: ${dtw['distance'] ?? '-'}'),
          Text(' - 점수: ${dtw['score'] ?? '-'}'),
          const SizedBox(height: 12),

          Text('LSTM 분석', style: _sectionTitle()),
          Text(' - 안정도 점수: ${lstm['score'] ?? '-'}'),
          const SizedBox(height: 12),

          Text('피드백', style: _sectionTitle()),
          Text(result['feedback'] ?? '피드백 없음'),
          const Divider(height: 30),

          if (result['comparison_video_path'] != null)
            _buildVideoPreview(result['comparison_video_path']),
        ],
      ),
    );
  }

  TextStyle _sectionTitle() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  );

  Widget _buildVideoPreview(String path) {
    final fileName = path.split('/').last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비교 영상', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            fileName,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '경로: $path',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

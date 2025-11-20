import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/preferences_helper.dart';
import '../../../../core/config/app_config.dart';
import 'analyze_screen.dart';

class VideoEditorScreen extends StatefulWidget {
  final String videoPath;
  final String style;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    required this.style,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  double _start = 0;
  double _end = 5;
  double _duration = 0;
  double _fps = 30;
  String? _convertedPath;
  bool _showPlayOverlay = true;

  @override
  void initState() {
    super.initState();
    _prepareVideo();
  }

  /// MOV → MP4 변환 + 회전 보정 + 리사이즈
  Future<void> _prepareVideo() async {
    try {
      final compressedVideo = await VideoCompress.compressVideo(
        widget.videoPath,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo == null || compressedVideo.path == null) {
        throw Exception('영상 압축 실패');
      }

      _convertedPath = compressedVideo.path;

      _controller = VideoPlayerController.file(File(_convertedPath!));
      await _controller.initialize();

      _duration = _controller.value.duration.inMilliseconds / 1000;

      setState(() {
        _fps = 30;
        _end = _duration;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("영상 변환 오류: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('영상 변환 중 오류 발생: $e')),
      );
    }
  }

  /// 분석 요청 및 화면 이동
  Future<void> _analyzeVideo() async {
    final uid = await PreferencesHelper.getUid();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final startFrame = (_start * _fps).round();
    final endFrame = (_end * _fps).round();
    final fileToSend = _convertedPath ?? widget.videoPath;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          fileToSend,
          filename: 'upload.mp4',
        ),
        'uid': uid,
        'pitchType': widget.style,
        'start_frame': startFrame.toString(),
        'end_frame': endFrame.toString(),
      });

      final response = await dio.post(
        '${AppConfig.baseUrl}api/analyze',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (!mounted) return;
      Navigator.pop(context); // 🔸 로딩 닫기

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyzeScreen(
              style: widget.style,
              videoPath: _convertedPath ?? widget.videoPath,
              startTime: _start,
              endTime: _end,
              resultData: response.data,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 요청 중 오류 발생: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    VideoCompress.cancelCompression();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('영상 구간 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _controller.value.isInitialized
                    ? GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                        _showPlayOverlay = false;
                      }
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 비율 유지 + 중앙 정렬
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),

                      // 처음에만 보이는 반투명 오버레이
                      if (_showPlayOverlay)
                        Container(
                          color: Colors.black38,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_circle_fill,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                )
                    : const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '분석 구간: ${_start.toStringAsFixed(1)}초 ~ ${_end.toStringAsFixed(1)}초',
              style: const TextStyle(fontSize: 16),
            ),
            RangeSlider(
              min: 0,
              max: _duration,
              values: RangeValues(_start, _end),
              onChanged: (values) {
                setState(() {
                  _start = values.start;
                  _end = values.end;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('이 구간으로 분석하기'),
              onPressed: _analyzeVideo,
            ),
          ],
        ),
      ),
    );
  }
}

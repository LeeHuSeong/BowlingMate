import 'package:flutter/material.dart';
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
  double _start = 0;
  double _end = 5;

  void _proceed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzeScreen(
          style: widget.style,
          videoPath: widget.videoPath,
          startTime: _start,
          endTime: _end,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영상 구간 선택')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('분석할 구간을 선택하세요'),
            const SizedBox(height: 20),
            RangeSlider(
              min: 0,
              max: 10,
              values: RangeValues(_start, _end),
              onChanged: (values) {
                setState(() {
                  _start = values.start;
                  _end = values.end;
                });
              },
            ),
            Text('선택 구간: ${_start.toStringAsFixed(1)}초 ~ ${_end.toStringAsFixed(1)}초'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _proceed,
              child: const Text('이 구간으로 분석하기'),
            ),
          ],
        ),
      ),
    );
  }
}

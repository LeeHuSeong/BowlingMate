import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnalyzeScreen extends StatefulWidget {
  final String style;
  final String videoPath;
  final double startTime;
  final double endTime;
  final dynamic resultData;

  const AnalyzeScreen({
    super.key,
    required this.style,
    required this.videoPath,
    required this.startTime,
    required this.endTime,
    required this.resultData,
  });

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  VideoPlayerController? _controller;
  bool _isVideoReady = false;
  bool _showPlayOverlay = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.resultData?['comparison_video_path'];
    if (videoUrl != null && videoUrl.toString().startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      setState(() => _isVideoReady = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _showPlayOverlay = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lstmScore = widget.resultData?['lstm']?['score']?.toString() ?? '-';
    final dtwScore = widget.resultData?['dtw']?['score']?.toString() ?? '-';
    final feedback = widget.resultData?['feedback'] ?? '피드백 정보 없음';

    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영상 (적당한 크기 + 비율 유지)
            Container(
              height: 430,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: _isVideoReady
                  ? GestureDetector(
                onTap: _togglePlayPause, // 전체 영상 터치로 재생/정지
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 중앙 정렬 유지 + 비율 맞춤
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),

                    // 처음에만 보이는 overlay 버튼
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
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 18),

            // 점수 카드
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScorePanel(
                        title: "LSTM 안정도",
                        score: lstmScore,
                        color: Colors.blueAccent,
                        icon: Icons.stacked_line_chart,
                        description: widget.resultData?['lstm']?['description'] ??
                            "AI 기반 프레임 안정도 (높을수록 일정함)",
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.shade300),
                      _buildScorePanel(
                        title: "DTW 유사도",
                        score: dtwScore,
                        color: Colors.deepPurpleAccent,
                        icon: Icons.auto_graph,
                        description: widget.resultData?['dtw']?['description'] ??
                            "기준 자세와의 프레임별 유사도 (높을수록 비슷함)",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 피드백 섹션
            const Text(
              "분석 피드백",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildFeedbackBox(feedback),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePanel({
    required String title,
    required String score,
    required Color color,
    required IconData icon,
    required String description,
  }) {
    final parsedScore = double.tryParse(score) ?? 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "${parsedScore.toStringAsFixed(1)}점",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 5,
          width: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: (parsedScore.clamp(0, 100)) / 100,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildFeedbackBox(String feedback) {
    final lines = feedback.split('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line.trim(),
            style: TextStyle(
              fontSize: line.startsWith('-') ? 15 : 16,
              height: 1.5,
              fontWeight: line.startsWith('**')
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: line.startsWith('-')
                  ? Colors.black87
                  : Colors.black,
            ),
          ),
        ))
            .toList(),
      ),
    );
  }
}

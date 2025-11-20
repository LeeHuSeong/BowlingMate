import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/preferences_helper.dart';
import 'analyze_screen.dart';

class AnalysisListScreen extends StatefulWidget {
  const AnalysisListScreen({super.key});

  @override
  State<AnalysisListScreen> createState() => _AnalysisListScreenState();
}

class _AnalysisListScreenState extends State<AnalysisListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalysisList();
  }

  Future<void> _fetchAnalysisList() async {
    try {
      final uid = await PreferencesHelper.getUid();
      final token = await PreferencesHelper.getJwt();

      if (uid == null || token == null) {
        setState(() => _error = "로그인 정보가 없습니다.");
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {"Authorization": "Bearer $token"},
      ));

      final response = await dio.get("api/analyze/history/$uid");

      if (response.statusCode == 200) {
        final data = (response.data as List).cast<Map<String, dynamic>>();
        setState(() {
          _records = data.reversed.toList(); // 최신순 정렬
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "서버 오류: ${response.statusMessage}";
          _isLoading = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('내 분석 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnalysisList,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            '⚠️ 오류: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        )
            : _records.isEmpty
            ? const Center(
          child: Text(
            '아직 분석 기록이 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        )
            : ListView.builder(
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final record = _records[index];
            return _buildRecordCard(record);
          },
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final pitchType = record['pitch_type'] ?? 'Unknown';
    final feedback = record['feedback'] ?? '';
    final date = record['created_at'] ?? '';
    final dtwScore = record['dtw']?['score']?.toStringAsFixed(2) ?? '-';
    final lstmScore = record['lstm']?['score']?.toStringAsFixed(2) ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            pitchType[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          pitchType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LSTM: $lstmScore / DTW: $dtwScore', style: const TextStyle(fontSize: 13)),
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (feedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  feedback.length > 60 ? '${feedback.substring(0, 60)}...' : feedback,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnalyzeScreen(
                style: pitchType,
                videoPath: record['comparison_video_path'] ?? '',
                startTime: 0,
                endTime: 0,
                resultData: record,
              ),
            ),
          );
        },
      ),
    );
  }
}

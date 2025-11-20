import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/preferences_helper.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../capture/presentation/screens/analyze_screen.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? name;
  String? email;
  String? phone;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchRecords();
  }

  Future<void> _loadUserInfo() async {
    name = await PreferencesHelper.getName();
    email = await PreferencesHelper.getEmail();
    phone = await PreferencesHelper.getPhone();
    setState(() {});
  }

  Future<void> _fetchRecords() async {
    try {
      final uid = await PreferencesHelper.getUid();
      final token = await PreferencesHelper.getJwt();
      if (uid == null || token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: {"Authorization": "Bearer $token"},
      ));

      final res = await dio.get("api/analyze/$uid");
      if (res.statusCode == 200) {
        final data = (res.data as List).cast<Map<String, dynamic>>();
        setState(() {
          _records = data.reversed.toList();
          _loading = false;
        });
      }
    } catch (e) {
      print("🔥 Error fetching records: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // 프로필 카드
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? '사용자 이름',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email ?? '이메일 정보 없음',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 메뉴 카드들
              _buildMenuCard(
                icon: Icons.analytics_outlined,
                title: '내 분석 기록 보기',
                onTap: () => _showAnalysisList(context),
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.lock_outline,
                title: '비밀번호 변경 (추후)',
                onTap: () {},
              ),
              const SizedBox(height: 12),

              _buildMenuCard(
                icon: Icons.logout,
                title: '로그아웃',
                onTap: () => _logout(context),
                color: Colors.redAccent,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.blueAccent,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _showAnalysisList(BuildContext context) {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분석 기록이 없습니다.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SizedBox(
        height: 500,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _records.length,
          itemBuilder: (context, i) {
            final record = _records[i];
            final pitch = record['pitch_type'] ?? '-';
            final date = record['created_at'] ?? '-';
            final lstm = record['lstm']?['score'] ?? '-';
            final dtw = record['dtw']?['score'] ?? '-';

            return ListTile(
              title: Text('$pitch / LSTM $lstm / DTW $dtw'),
              subtitle: Text(date),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalyzeScreen(
                    style: pitch,
                    videoPath: record['comparison_video_path'] ?? '',
                    startTime: 0,
                    endTime: 0,
                    resultData: record,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

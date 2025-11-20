import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'upload_or_camera_screen.dart';

class StyleSelectionScreen extends StatelessWidget {
  const StyleSelectionScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 확인'),
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
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  void _navigateToNext(BuildContext context, String style) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UploadOrCameraScreen(style: style)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = [
      {'name': '스트로커', 'color': const Color(0xFF64B5F6)},
      {'name': '투핸드', 'color': const Color(0xFF42A5F5)},
      {'name': '덤리스', 'color': const Color(0xFF1E88E5)},
      {'name': '크랭커', 'color': const Color(0xFF1565C0)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('투구 스타일 선택'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              '분석할 구질을 선택하세요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.builder(
                itemCount: styles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = styles[index];
                  final color = item['color'] as Color;
                  final style = item['name'] as String;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _navigateToNext(context, style),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          style,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '구질에 따라 AI가 자세를 분석하고\n맞춤 피드백을 제공합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

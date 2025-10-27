import 'package:flutter/material.dart';
import '../../../../core/utils/preferences_helper.dart';
import 'video_editor_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class UploadOrCameraScreen extends StatelessWidget {
  final String style;
  const UploadOrCameraScreen({super.key, required this.style});

  Future<void> _checkAuth(BuildContext context) async {
    final jwt = await PreferencesHelper.getJwt();
    if (jwt == null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _onSelectVideo(BuildContext context, String source) async {
    await _checkAuth(context);

    // TODO: video_picker_service 연결 예정
    final fakeVideoPath = '/storage/emulated/0/DCIM/test_video.mp4';

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(
            videoPath: fakeVideoPath,
            style: style,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$style - 영상 선택')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '영상을 업로드하거나\n직접 촬영하여 분석을 시작하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('영상 업로드'),
              onPressed: () => _onSelectVideo(context, 'upload'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
              onPressed: () => _onSelectVideo(context, 'camera'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/preferences_helper.dart';
import 'video_editor_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'dart:io';

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

  /// 영상 선택
  Future<void> _onSelectVideo(BuildContext context, String source) async {
    await _checkAuth(context);

    final picker = ImagePicker();
    XFile? pickedFile;

    if (source == 'upload') {
      // 갤러리에서 영상 선택
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    } else if (source == 'camera') {
      // 카메라로 촬영 (에뮬레이터에서는 작동하지 않음)
      pickedFile = await picker.pickVideo(source: ImageSource.camera);
    }

    if (pickedFile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영상이 선택되지 않았습니다.')),
        );
      }
      return;
    }

    final videoPath = pickedFile.path;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(
            videoPath: videoPath,
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라로 촬영'),
                  onPressed: () => _onSelectVideo(context, 'camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

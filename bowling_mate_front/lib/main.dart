import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/signup_usecase.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/capture/presentation/screens/main_navigation_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/preferences_helper.dart';

void main() {
  final authRemoteDataSource = AuthRemoteDataSource();
  final authRepository = AuthRepositoryImpl(authRemoteDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            loginUseCase: LoginUseCase(authRepository),
            signupUseCase: SignupUseCase(authRepository),
          ),
        ),
      ],
      child: const BowlingMateApp(),
    ),
  );
}

class BowlingMateApp extends StatelessWidget {
  const BowlingMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bowling Mate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/main': (_) => const MainNavigationScreen(),
      },
    );
  }
}

/// 로그인 여부 체크 후 라우팅
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await PreferencesHelper.getJwt();
    await Future.delayed(const Duration(milliseconds: 400)); // 약간의 딜레이로 부드럽게
    setState(() {
      _loggedIn = token != null && token.isNotEmpty;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF1565C0)),
              SizedBox(height: 18),
              Text(
                "Bowling Mate 로딩 중...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _loggedIn ? const MainNavigationScreen() : const LoginScreen();
  }
}

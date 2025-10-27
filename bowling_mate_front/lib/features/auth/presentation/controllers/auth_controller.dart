import 'package:flutter/material.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/entities/user.dart';
import '../../data/models/login_request.dart';
import '../../data/models/signup_request.dart';

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;

  bool isLoading = false;
  String? error;
  User? user;

  AuthController({
    required this.loginUseCase,
    required this.signupUseCase,
  });

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await loginUseCase.execute(LoginRequest(email: email, password: password));
    } catch (e) {
      error = "로그인 실패: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String name, String phone) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      user = await signupUseCase.execute(
        SignupRequest(email: email, password: password, name: name, phone: phone),
      );
    } catch (e) {
      error = "회원가입 실패: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
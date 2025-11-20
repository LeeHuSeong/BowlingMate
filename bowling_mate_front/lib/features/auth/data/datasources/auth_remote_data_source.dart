import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../models/signup_request.dart';
import '../models/signup_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRemoteDataSource {
  final Dio dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await dio.post('api/auth/login', data: request.toJson());
    return LoginResponse.fromJson(response.data);
  }

  Future<SignupResponse> signup(SignupRequest request) async {
    final response = await dio.post('api/auth/signup', data: request.toJson());
    return SignupResponse.fromJson(response.data);
  }
}

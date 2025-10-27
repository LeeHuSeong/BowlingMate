import '../entities/user.dart';
import '../../data/models/login_request.dart';
import '../../data/models/signup_request.dart';

abstract class AuthRepository {
  Future<User> login(LoginRequest request);
  Future<User> signup(SignupRequest request);
}

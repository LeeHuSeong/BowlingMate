import '../repositories/auth_repository.dart';
import '../entities/user.dart';
import '../../data/models/login_request.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<User> execute(LoginRequest request) => repository.login(request);
}
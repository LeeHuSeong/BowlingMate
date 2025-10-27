import '../repositories/auth_repository.dart';
import '../entities/user.dart';
import '../../data/models/signup_request.dart';

class SignupUseCase {
  final AuthRepository repository;
  SignupUseCase(this.repository);

  Future<User> execute(SignupRequest request) => repository.signup(request);
}
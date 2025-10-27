import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request.dart';
import '../models/signup_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login(LoginRequest request) async {
    final response = await remoteDataSource.login(request);
    return User(
      uid: response.uid,
      email: response.email,
      name: response.name,
      role: response.role,
      phone: response.phone,
      jwt: response.jwt,
    );
  }

  @override
  Future<User> signup(SignupRequest request) async {
    final response = await remoteDataSource.signup(request);
    return User(
      uid: response.uid,
      email: response.email,
      name: response.name,
      role: response.role,
      phone: response.phone,
      jwt: response.jwt,
    );
  }
}

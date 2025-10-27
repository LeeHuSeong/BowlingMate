class SignupRequest {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String role; // 예: USER, ADMIN 등

  SignupRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    this.role = "USER",
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'userName': name,
    'phone': phone,
    'role': role,
  };
}

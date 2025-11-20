class LoginResponse {
  final String jwt;
  final String uid;
  final String email;
  final String name;
  final String role;
  final String phone;

  LoginResponse({
    required this.jwt,
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      jwt: json['jwt'] ?? '',
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['userName'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

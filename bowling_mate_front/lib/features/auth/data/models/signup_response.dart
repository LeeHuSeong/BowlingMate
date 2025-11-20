class SignupResponse {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String phone;
  final String jwt;

  SignupResponse({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    required this.jwt,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['userName'] ?? '',
      role: json['role'] ?? 'USER',
      phone: json['phone'] ?? '',
      jwt: json['jwt'] ?? '',
    );
  }
}

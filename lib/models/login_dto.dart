// models/login_dto.dart
class LoginDto {
  final String email;
  final String password;

  LoginDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
    };
  }

  factory LoginDto.fromJson(Map<String, dynamic> json) {
    return LoginDto(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }
}
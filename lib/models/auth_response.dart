// models/auth_response.dart
import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;
  final String? message;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user'] ?? {}),
      message: json['message'],
    );
  }
  
  // Для обратной совместимости
  String get token => accessToken;
}
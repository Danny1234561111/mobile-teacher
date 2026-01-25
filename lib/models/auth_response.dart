// models/auth_response.dart
import 'user.dart';
class AuthResponse {
  final String token;
  final String? refreshToken;
  final String? userId;
  final User user;
  final String? message;
  final int? expiresIn;
  final String? firebaseUid;

  AuthResponse({
    required this.token,
    this.refreshToken,
    this.userId,
    required this.user,
    this.message,
    this.expiresIn,
    this.firebaseUid,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      userId: json['user_id'] ?? json['userId'],
      user: User.fromJson(json['user'] ?? {}),
      message: json['message'] ?? '',
      expiresIn: json['expires_in'] ?? json['expiresIn'],
      firebaseUid: json['firebase_uid'] ?? json['firebaseUid'],
    );
  }
}

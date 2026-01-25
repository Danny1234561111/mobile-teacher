// models/register_dto.dart
class RegisterDto {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? direction;
  final int? maxStudents;
  final String role;

  RegisterDto({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.direction,
    this.maxStudents = 20,
    this.role = 'teacher',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'direction': direction,
      'max_students': maxStudents,
      'role': role,
    };
  }

  factory RegisterDto.fromJson(Map<String, dynamic> json) {
    return RegisterDto(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.tryParse(json['date_of_birth']) 
          : null,
      direction: json['direction'],
      maxStudents: json['max_students'] ?? json['maxStudents'] ?? 20,
      role: json['role'] ?? 'teacher',
    );
  }
}
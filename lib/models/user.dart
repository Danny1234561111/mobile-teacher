
// models/user.dart
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? firebaseUserId;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;
  final String? phone;
  final String? direction;
  final int? maxStudents;
  final int? currentStudentsCount;
  final String? dateOfBirth;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.firebaseUserId,
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.phone,
    this.direction,
    this.maxStudents,
    this.currentStudentsCount,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      role: json['role'] ?? 'teacher',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      firebaseUserId: json['firebase_user_id'] ?? json['firebaseUserId'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      phone: json['phone'],
      direction: json['direction'],
      maxStudents: json['max_students'] ?? json['maxStudents'],
      currentStudentsCount: json['current_students_count'] ?? json['currentStudentsCount'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'firebase_user_id': firebaseUserId,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'phone': phone,
      'direction': direction,
      'max_students': maxStudents,
      'current_students_count': currentStudentsCount,
      'date_of_birth': dateOfBirth,
    };
  }
}
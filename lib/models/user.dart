// models/user.dart
import 'package:flutter/material.dart'; // ⚠️ ОБЯЗАТЕЛЬНО добавить этот импорт!

class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  // НОВЫЕ ПОЛЯ ДЛЯ АКТИВНОГО КОНТАКТА
  final String? activeContact;
  final String? activeContactType;
  final DateTime? activeContactUpdatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.activeContact,
    this.activeContactType,
    this.activeContactUpdatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      activeContact: json['active_contact'],
      activeContactType: json['active_contact_type'],
      activeContactUpdatedAt: json['active_contact_updated_at'] != null 
          ? DateTime.tryParse(json['active_contact_updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'active_contact': activeContact,
      'active_contact_type': activeContactType,
      'active_contact_updated_at': activeContactUpdatedAt?.toIso8601String(),
    };
  }
  
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isTeacher => role.toLowerCase() == 'teacher';
  bool get isStudent => role.toLowerCase() == 'student';
  
  // Проверка наличия активного контакта
  bool get hasActiveContact => activeContact != null && activeContact!.isNotEmpty;
  
  // Получение отображаемого имени для типа контакта
  String get activeContactTypeDisplay {
    switch (activeContactType?.toLowerCase()) {
      case 'telegram': return 'Telegram';
      case 'whatsapp': return 'WhatsApp';
      case 'sms': return 'SMS';
      case 'call': return 'Звонок';
      default: return activeContactType ?? 'Контакт';
    }
  }
  
  // Получение иконки для типа контакта
  IconData get activeContactIcon {
    switch (activeContactType?.toLowerCase()) {
      case 'telegram': return Icons.telegram;
      case 'whatsapp': return Icons.chat;
      case 'sms': return Icons.sms;
      case 'call': return Icons.phone;
      default: return Icons.contact_phone;
    }
  }
}
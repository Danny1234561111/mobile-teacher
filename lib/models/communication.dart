import 'dart:convert';

class Communication {
  final String id;
  final String studentId;
  final String communicationType;
  final String status;
  final DateTime dateTime;
  final int? durationMinutes;
  final String topic;
  final String notes;
  final String? nextAction;
  final DateTime? nextActionDate;
  final List<String> attachmentUrls;
  final bool isImportant;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? studentName;
  final String? studentPhone;

  Communication({
    required this.id,
    required this.studentId,
    required this.communicationType,
    required this.status,
    required this.dateTime,
    this.durationMinutes,
    required this.topic,
    required this.notes,
    this.nextAction,
    this.nextActionDate,
    required this.attachmentUrls,
    required this.isImportant,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.studentName,
    this.studentPhone,
  });

  factory Communication.fromJson(Map<String, dynamic> json) {
    return Communication(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      communicationType: json['communication_type'] as String,
      status: json['status'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      topic: json['topic'] as String,
      notes: json['notes'] as String,
      nextAction: json['next_action'] as String?,
      nextActionDate: json['next_action_date'] != null
          ? DateTime.parse(json['next_action_date'] as String)
          : null,
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      isImportant: json['is_important'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      studentName: json['student_name'] as String?,
      studentPhone: json['student_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'communication_type': communicationType,
      'status': status,
      'date_time': dateTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'topic': topic,
      'notes': notes,
      'next_action': nextAction,
      'next_action_date': nextActionDate?.toIso8601String(),
      'attachment_urls': attachmentUrls,
      'is_important': isImportant,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'student_name': studentName,
      'student_phone': studentPhone,
    };
  }

  String get typeDisplayName {
    switch (communicationType) {
      case 'call':
        return 'Звонок';
      case 'meeting':
        return 'Встреча';
      case 'email':
        return 'Email';
      case 'message':
        return 'Сообщение';
      default:
        return 'Другое';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'planned':
        return 'Запланировано';
      case 'completed':
        return 'Завершено';
      case 'cancelled':
        return 'Отменено';
      case 'rescheduled':
        return 'Перенесено';
      default:
        return status;
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateDay == today) {
      return 'Сегодня ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String get durationDisplay {
    if (durationMinutes == null) return '';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    
    if (hours > 0) {
      return '$hours ч ${minutes} мин';
    } else {
      return '$minutes мин';
    }
  }
}
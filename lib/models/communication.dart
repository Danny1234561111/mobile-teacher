// models/communication.dart
class Communication {
  final int id;
  final int studentId;
  final String? studentName;
  final String communicationType;
  final String status;
  final DateTime dateTime;
  final int? durationMinutes;
  final String notes;
  final String? createdByName;
  final DateTime createdAt;

  Communication({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.communicationType,
    required this.status,
    required this.dateTime,
    this.durationMinutes,
    required this.notes,
    this.createdByName,
    required this.createdAt,
  });

  factory Communication.fromJson(Map<String, dynamic> json) {
    return Communication(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      studentId: json['student_id'] is int 
          ? json['student_id'] 
          : int.tryParse(json['student_id'].toString()) ?? 0,
      studentName: json['student_name'],
      communicationType: json['communication_type'] ?? '',
      status: json['status'] ?? '',
      dateTime: DateTime.parse(json['date_time'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['duration_minutes'] != null 
          ? int.tryParse(json['duration_minutes'].toString()) 
          : null,
      notes: json['notes'] ?? '',
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'communication_type': communicationType,
      'status': status,
      'date_time': dateTime.toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'notes': notes,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'communication_type': communicationType,
      'status': status,
      'date_time': dateTime.toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'notes': notes,
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
        return communicationType;
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
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
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
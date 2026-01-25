import 'dart:convert';

class Student {
  final String? id;
  final String russianStudentId;
  final String fullName;
  final String phone;
  final String? email;
  final String? assignedTeacherId;
  final String? assignedTeacherName;
  final String? status;
  final List<dynamic>? additionalContacts;
  final String? dateOfBirth;
  final String? createdAt;
  final String? updatedAt;
  final String? departmentId;
  final String? departmentName;
  final String? specialityId;
  final String? specialityName;
  final int? priorityPlace;
  final String? level;
  final String? notes;
  final bool? isActive;
  final DateTime? lastCommunicationDate;

  Student({
    this.id,
    required this.russianStudentId,
    required this.fullName,
    required this.phone,
    this.email,
    this.assignedTeacherId,
    this.assignedTeacherName,
    this.status = 'active',
    this.additionalContacts,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
    this.departmentId,
    this.departmentName,
    this.specialityId,
    this.specialityName,
    this.priorityPlace = 1,
    this.level,
    this.notes,
    this.isActive = true,
    this.lastCommunicationDate,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    
    List<dynamic>? additionalContacts;
    if (json['additional_contacts'] != null) {
      if (json['additional_contacts'] is String) {
        try {
          additionalContacts = jsonDecode(json['additional_contacts']);
        } catch (e) {
          additionalContacts = [json['additional_contacts']];
        }
      } else if (json['additional_contacts'] is List) {
        additionalContacts = List<dynamic>.from(json['additional_contacts']);
      }
    } else if (json['additionalContacts'] != null) {
      if (json['additionalContacts'] is String) {
        try {
          additionalContacts = jsonDecode(json['additionalContacts']);
        } catch (e) {
          additionalContacts = [json['additionalContacts']];
        }
      } else if (json['additionalContacts'] is List) {
        additionalContacts = List<dynamic>.from(json['additionalContacts']);
      }
    }

    String? dateOfBirth;
    if (json['date_of_birth'] != null) {
      dateOfBirth = json['date_of_birth'].toString();
    } else if (json['dateOfBirth'] != null) {
      dateOfBirth = json['dateOfBirth'].toString();
    }

    String? createdAt;
    if (json['created_at'] != null) {
      createdAt = json['created_at'].toString();
    } else if (json['createdAt'] != null) {
      createdAt = json['createdAt'].toString();
    }

    String? updatedAt;
    if (json['updated_at'] != null) {
      updatedAt = json['updated_at'].toString();
    } else if (json['updatedAt'] != null) {
      updatedAt = json['updatedAt'].toString();
    }

    DateTime? lastCommunicationDate;
    if (json['last_communication_date'] != null) {
      try {
        lastCommunicationDate = DateTime.parse(json['last_communication_date'].toString());
      } catch (e) {
        print('Error parsing last_communication_date: $e');
      }
    }

    return Student(
      id: id,
      russianStudentId: json['russian_student_id']?.toString() ?? 
                       json['russianStudentId']?.toString() ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      assignedTeacherId: json['assigned_teacher_id']?.toString() ?? 
                        json['assignedTeacherId']?.toString(),
      assignedTeacherName: json['assigned_teacher_name']?.toString() ?? 
                          json['assignedTeacherName']?.toString(),
      status: json['status']?.toString() ?? 'active',
      additionalContacts: additionalContacts,
      dateOfBirth: dateOfBirth,
      createdAt: createdAt,
      updatedAt: updatedAt,
      departmentId: json['department_id']?.toString() ?? json['departmentId']?.toString(),
      departmentName: json['department_name']?.toString() ?? json['departmentName']?.toString(),
      specialityId: json['speciality_id']?.toString() ?? json['specialityId']?.toString(),
      specialityName: json['speciality_name']?.toString() ?? json['specialityName']?.toString(),
      priorityPlace: json['priority_place'] != null 
          ? int.tryParse(json['priority_place'].toString())
          : json['priorityPlace'] != null
              ? int.tryParse(json['priorityPlace'].toString())
              : 1,
      level: json['level']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      lastCommunicationDate: lastCommunicationDate,
    );
  }

  Map<String, dynamic> toJson() {
    final jsonMap = <String, dynamic>{
      'russian_student_id': russianStudentId,
      'full_name': fullName,
      'phone': phone,
      'status': status ?? 'active',
      'is_active': isActive ?? true,
    };

    if (email != null) jsonMap['email'] = email;
    if (assignedTeacherId != null && assignedTeacherId!.isNotEmpty) {
      jsonMap['assigned_teacher_id'] = assignedTeacherId;
    }
    if (assignedTeacherName != null && assignedTeacherName!.isNotEmpty) {
      jsonMap['assigned_teacher_name'] = assignedTeacherName;
    }
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty) {
      jsonMap['date_of_birth'] = dateOfBirth;
    }
    if (additionalContacts != null && additionalContacts!.isNotEmpty) {
      jsonMap['additional_contacts'] = additionalContacts;
    }
    if (departmentId != null) jsonMap['department_id'] = departmentId;
    if (specialityId != null) jsonMap['speciality_id'] = specialityId;
    if (priorityPlace != null) jsonMap['priority_place'] = priorityPlace;
    if (level != null) jsonMap['level'] = level;
    if (notes != null) jsonMap['notes'] = notes;

    return jsonMap;
  }

  Map<String, dynamic> toCreateJson() {
    final jsonMap = toJson();
    jsonMap.remove('id');
    jsonMap.remove('created_at');
    jsonMap.remove('updated_at');
    jsonMap.remove('assigned_teacher_name');
    jsonMap.remove('department_name');
    jsonMap.remove('speciality_name');
    jsonMap.remove('last_communication_date');
    return jsonMap;
  }

  Student copyWith({
    String? id,
    String? russianStudentId,
    String? fullName,
    String? phone,
    String? email,
    String? assignedTeacherId,
    String? assignedTeacherName,
    String? status,
    List<dynamic>? additionalContacts,
    String? dateOfBirth,
    String? createdAt,
    String? updatedAt,
    String? departmentId,
    String? departmentName,
    String? specialityId,
    String? specialityName,
    int? priorityPlace,
    String? level,
    String? notes,
    bool? isActive,
    DateTime? lastCommunicationDate,
  }) {
    return Student(
      id: id ?? this.id,
      russianStudentId: russianStudentId ?? this.russianStudentId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedTeacherId: assignedTeacherId ?? this.assignedTeacherId,
      assignedTeacherName: assignedTeacherName ?? this.assignedTeacherName,
      status: status ?? this.status,
      additionalContacts: additionalContacts ?? this.additionalContacts,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      specialityId: specialityId ?? this.specialityId,
      specialityName: specialityName ?? this.specialityName,
      priorityPlace: priorityPlace ?? this.priorityPlace,
      level: level ?? this.level,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      lastCommunicationDate: lastCommunicationDate ?? this.lastCommunicationDate,
    );
  }

  bool isValid() {
    return russianStudentId.isNotEmpty && 
           fullName.isNotEmpty && 
           phone.isNotEmpty &&
           russianStudentId.length >= 5;
  }

  String get displayName => fullName;
  String get displayId => russianStudentId;
  String get displayPhone => _formatPhone(phone);

  String _formatPhone(String phone) {
    if (phone.length >= 11) {
      return '+${phone.substring(0, 1)} (${phone.substring(1, 4)}) ${phone.substring(4, 7)}-${phone.substring(7, 9)}-${phone.substring(9)}';
    }
    return phone;
  }

  String get statusText {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Активный';
      case 'inactive':
        return 'Неактивный';
      case 'graduated':
        return 'Выпускник';
      case 'dropped':
        return 'Отчислился';
      case 'suspended':
        return 'Приостановлен';
      default:
        return 'Активный';
    }
  }

  int get statusColor {
    switch (status?.toLowerCase()) {
      case 'active':
        return 0xFF4CAF50;
      case 'inactive':
        return 0xFFF44336;
      case 'graduated':
        return 0xFF2196F3;
      case 'dropped':
        return 0xFFFF9800;
      case 'suspended':
        return 0xFFFF9800;
      default:
        return 0xFF9E9E9E;
    }
  }

  @override
  String toString() {
    return 'Student{id: $id, name: $fullName, phone: $phone, russianId: $russianStudentId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          russianStudentId == other.russianStudentId;

  @override
  int get hashCode => id.hashCode ^ russianStudentId.hashCode;
}
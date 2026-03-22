// models/student.dart
class Student {
  final int id;
  final int russianStudentId;
  final String fullName;
  final String phone;
  final Map<String, dynamic>? additionalContacts;
  final String? priorContact;
  final int? departmentId;
  final String? departmentName;
  final int? specialityId;
  final String? specialityName;
  final int? profileId;
  final String? profileName;
  final String? studyLevel;
  final String? studyForm;
  final String? studyBasis;
  final String? status;
  final String? applicationStatus;
  final String? contactStatus;
  final String? contactType;
  final bool? consentStatus;
  final int? totalScore;
  final DateTime? lastCommunication;
  final String? lastCommunicationNote;
  final int? kuratorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Student({
    required this.id,
    required this.russianStudentId,
    required this.fullName,
    required this.phone,
    this.additionalContacts,
    this.priorContact,
    this.departmentId,
    this.departmentName,
    this.specialityId,
    this.specialityName,
    this.profileId,
    this.profileName,
    this.studyLevel,
    this.studyForm,
    this.studyBasis,
    this.status,
    this.applicationStatus,
    this.contactStatus,
    this.contactType,
    this.consentStatus,
    this.totalScore,
    this.lastCommunication,
    this.lastCommunicationNote,
    this.kuratorId,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      russianStudentId: json['russian_student_id'] is int 
          ? json['russian_student_id'] 
          : int.tryParse(json['russian_student_id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      additionalContacts: json['additional_contacts'] is Map 
          ? Map<String, dynamic>.from(json['additional_contacts']) 
          : null,
      priorContact: json['prior_contact'],
      departmentId: json['department_id'] != null 
          ? int.tryParse(json['department_id'].toString()) 
          : null,
      departmentName: json['department_name'],
      specialityId: json['speciality_id'] != null 
          ? int.tryParse(json['speciality_id'].toString()) 
          : null,
      specialityName: json['speciality_name'],
      profileId: json['profile_id'] != null 
          ? int.tryParse(json['profile_id'].toString()) 
          : null,
      profileName: json['profile_name'],
      studyLevel: json['study_level'],
      studyForm: json['study_form'],
      studyBasis: json['study_basis'],
      status: json['status'],
      applicationStatus: json['application_status'],
      contactStatus: json['contact_status'],
      contactType: json['contact_type'],
      consentStatus: json['consent_status'],
      totalScore: json['total_score'] != null 
          ? int.tryParse(json['total_score'].toString()) 
          : null,
      lastCommunication: json['last_communication'] != null 
          ? DateTime.tryParse(json['last_communication']) 
          : null,
      lastCommunicationNote: json['last_communication_note'],
      kuratorId: json['kurator_id'] != null 
          ? int.tryParse(json['kurator_id'].toString()) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'russian_student_id': russianStudentId,
      'full_name': fullName,
      'phone': phone,
      if (additionalContacts != null) 'additional_contacts': additionalContacts,
      if (priorContact != null) 'prior_contact': priorContact,
      if (departmentId != null) 'department_id': departmentId,
      if (specialityId != null) 'speciality_id': specialityId,
      if (profileId != null) 'profile_id': profileId,
      if (studyLevel != null) 'study_level': studyLevel,
      if (studyForm != null) 'study_form': studyForm,
      if (studyBasis != null) 'study_basis': studyBasis,
      if (status != null) 'status': status,
      if (applicationStatus != null) 'application_status': applicationStatus,
      if (contactStatus != null) 'contact_status': contactStatus,
      if (contactType != null) 'contact_type': contactType,
      if (consentStatus != null) 'consent_status': consentStatus,
      if (totalScore != null) 'total_score': totalScore,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'full_name': fullName,
      'russian_student_id': russianStudentId,
      'phone': phone,
    };
  }

  String get displayName => fullName;
  String get displayId => russianStudentId.toString();
  
  String get displayPhone {
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
      default:
        return status ?? 'Активный';
    }
  }

  @override
  String toString() {
    return 'Student{id: $id, name: $fullName, phone: $phone, russianId: $russianStudentId}';
  }
}
// models/student_application.dart
class StudentApplication {
  final int id;
  final int studentId;
  final int departmentId;
  final String? departmentName;  // сделано nullable
  final int specialityId;
  final String? specialityName;  // сделано nullable
  final int? profileId;
  final String? profileName;
  final int? position;
  final int? priority;
  final int? totalScore;
  final String? applicationStatus;
  final bool consentStatus;
  final bool participation;
  final bool isMainContest;
  final String? studyForm;  // добавлено
  final String? studyBasis;  // добавлено
  final String? studyLevel;  // добавлено
  final int? budgetPlacesTotal;  // добавлено
  final int? budgetPlacesFilled;  // добавлено
  final int? paidPlacesTotal;  // добавлено
  final int? paidPlacesFilled;  // добавлено
  final int? targetPlacesTotal;  // добавлено
  final int? targetPlacesFilled;  // добавлено
  final DateTime? createdAt;  // сделано nullable
  final DateTime? updatedAt;  // сделано nullable

  StudentApplication({
    required this.id,
    required this.studentId,
    required this.departmentId,
    this.departmentName,
    required this.specialityId,
    this.specialityName,
    this.profileId,
    this.profileName,
    this.position,
    this.priority,
    this.totalScore,
    this.applicationStatus,
    required this.consentStatus,
    required this.participation,
    required this.isMainContest,
    this.studyForm,
    this.studyBasis,
    this.studyLevel,
    this.budgetPlacesTotal,
    this.budgetPlacesFilled,
    this.paidPlacesTotal,
    this.paidPlacesFilled,
    this.targetPlacesTotal,
    this.targetPlacesFilled,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentApplication.fromJson(Map<String, dynamic> json) {
    return StudentApplication(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'],
      specialityId: json['speciality_id'] ?? 0,
      specialityName: json['speciality_name'],
      profileId: json['profile_id'],
      profileName: json['profile_name'],
      position: json['position'],
      priority: json['priority'],
      totalScore: json['total_score'],
      applicationStatus: json['application_status'],
      consentStatus: json['consent_status'] ?? false,
      participation: json['participation'] ?? true,
      isMainContest: json['is_main_contest'] ?? false,
      studyForm: json['study_form'],
      studyBasis: json['study_basis'],
      studyLevel: json['study_level'],
      budgetPlacesTotal: json['budget_places_total'],
      budgetPlacesFilled: json['budget_places_filled'],
      paidPlacesTotal: json['paid_places_total'],
      paidPlacesFilled: json['paid_places_filled'],
      targetPlacesTotal: json['target_places_total'],
      targetPlacesFilled: json['target_places_filled'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
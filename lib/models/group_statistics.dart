// models/group_statistics.dart
class GroupStatistics {
  final String groupName;
  final int? profileId;
  final String? studyForm;
  final String? studyBasis;
  final int totalApplications;
  final int applicationsSubmitted;
  final int enrolled;
  final double averageScore;
  final int minScore;
  final int maxScore;
  final BudgetStatistics budget;
  final PaidStatistics paid;
  final TargetStatistics target;
  final double competition;
  final int passingScoreCurrent;
  final int passingScoreLastYear;

  GroupStatistics({
    required this.groupName,
    this.profileId,
    this.studyForm,
    this.studyBasis,
    required this.totalApplications,
    required this.applicationsSubmitted,
    required this.enrolled,
    required this.averageScore,
    required this.minScore,
    required this.maxScore,
    required this.budget,
    required this.paid,
    required this.target,
    required this.competition,
    required this.passingScoreCurrent,
    required this.passingScoreLastYear,
  });

  factory GroupStatistics.fromJson(Map<String, dynamic> json) {
    return GroupStatistics(
      groupName: json['group_name']?.toString() ?? '',
      profileId: json['profile_id'] != null ? json['profile_id'] as int : null,
      studyForm: json['study_form']?.toString(),
      studyBasis: json['study_basis']?.toString(),
      totalApplications: json['total_applications'] as int? ?? 0,
      applicationsSubmitted: json['applications_submitted'] as int? ?? 0,
      enrolled: json['enrolled'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      minScore: json['min_score'] as int? ?? 0,
      maxScore: json['max_score'] as int? ?? 0,
      budget: BudgetStatistics.fromJson(json['budget'] as Map<String, dynamic>? ?? {}),
      paid: PaidStatistics.fromJson(json['paid'] as Map<String, dynamic>? ?? {}),
      target: TargetStatistics.fromJson(json['target'] as Map<String, dynamic>? ?? {}),
      competition: (json['competition'] as num?)?.toDouble() ?? 0.0,
      passingScoreCurrent: json['passing_score_current'] as int? ?? 0,
      passingScoreLastYear: json['passing_score_last_year'] as int? ?? 0,
    );
  }

  /// Пустой объект статистики (для случаев, когда данные не найдены)
  factory GroupStatistics.empty() {
    return GroupStatistics(
      groupName: '',
      profileId: null,
      studyForm: null,
      studyBasis: null,
      totalApplications: 0,
      applicationsSubmitted: 0,
      enrolled: 0,
      averageScore: 0.0,
      minScore: 0,
      maxScore: 0,
      budget: BudgetStatistics.empty(),
      paid: PaidStatistics.empty(),
      target: TargetStatistics.empty(),
      competition: 0.0,
      passingScoreCurrent: 0,
      passingScoreLastYear: 0,
    );
  }

  /// Проверка, является ли объект пустым
  bool get isEmpty => groupName.isEmpty;
  
  /// Проверка, является ли объект непустым
  bool get isNotEmpty => groupName.isNotEmpty;
}

/// Статистика по бюджетным местам
class BudgetStatistics {
  final int total;
  final int filled;
  final int free;
  final int applicantsInRange;
  final int applicantsWithConsent;
  final int passingScore;

  BudgetStatistics({
    required this.total,
    required this.filled,
    required this.free,
    required this.applicantsInRange,
    required this.applicantsWithConsent,
    required this.passingScore,
  });

  factory BudgetStatistics.fromJson(Map<String, dynamic> json) {
    return BudgetStatistics(
      total: json['total'] as int? ?? 0,
      filled: json['filled'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      applicantsInRange: json['applicants_in_range'] as int? ?? 0,
      applicantsWithConsent: json['applicants_with_consent'] as int? ?? 0,
      passingScore: json['passing_score'] as int? ?? 0,
    );
  }

  factory BudgetStatistics.empty() {
    return BudgetStatistics(
      total: 0,
      filled: 0,
      free: 0,
      applicantsInRange: 0,
      applicantsWithConsent: 0,
      passingScore: 0,
    );
  }
}

/// Статистика по платным местам
class PaidStatistics {
  final int total;
  final int filled;
  final int free;
  final int applicantsWithConsent;

  PaidStatistics({
    required this.total,
    required this.filled,
    required this.free,
    required this.applicantsWithConsent,
  });

  factory PaidStatistics.fromJson(Map<String, dynamic> json) {
    return PaidStatistics(
      total: json['total'] as int? ?? 0,
      filled: json['filled'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      applicantsWithConsent: json['applicants_with_consent'] as int? ?? 0,
    );
  }

  factory PaidStatistics.empty() {
    return PaidStatistics(
      total: 0,
      filled: 0,
      free: 0,
      applicantsWithConsent: 0,
    );
  }
}

/// Статистика по целевым местам
class TargetStatistics {
  final int total;
  final int filled;
  final int free;
  final int applicantsWithConsent;

  TargetStatistics({
    required this.total,
    required this.filled,
    required this.free,
    required this.applicantsWithConsent,
  });

  factory TargetStatistics.fromJson(Map<String, dynamic> json) {
    return TargetStatistics(
      total: json['total'] as int? ?? 0,
      filled: json['filled'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      applicantsWithConsent: json['applicants_with_consent'] as int? ?? 0,
    );
  }

  factory TargetStatistics.empty() {
    return TargetStatistics(
      total: 0,
      filled: 0,
      free: 0,
      applicantsWithConsent: 0,
    );
  }
}
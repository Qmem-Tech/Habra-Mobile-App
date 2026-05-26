import 'package:equatable/equatable.dart';

/// One work-history row the applicant adds on the apply form (stored in `job_applications.experience` JSONB).
class ApplicationExperienceEntry extends Equatable {
  final String title;
  final String company;
  /// Stored slug: full-time, part-time, contract, internship
  final String employmentTypeSlug;
  final int startYear;
  final int startMonth;
  final int? endYear;
  final int? endMonth;
  final bool isCurrent;

  const ApplicationExperienceEntry({
    required this.title,
    required this.company,
    required this.employmentTypeSlug,
    required this.startYear,
    required this.startMonth,
    this.endYear,
    this.endMonth,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'company': company,
        'employment_type': employmentTypeSlug,
        'start_year': startYear,
        'start_month': startMonth,
        'is_current': isCurrent,
        if (!isCurrent && endYear != null) 'end_year': endYear,
        if (!isCurrent && endMonth != null) 'end_month': endMonth,
      };

  @override
  List<Object?> get props => [
        title,
        company,
        employmentTypeSlug,
        startYear,
        startMonth,
        endYear,
        endMonth,
        isCurrent,
      ];
}

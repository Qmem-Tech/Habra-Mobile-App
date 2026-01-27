import 'package:equatable/equatable.dart';

/// Job filters entity
class JobFilters extends Equatable {
  final List<String> categories; // e.g., ["Homecare", "Trucking"]
  final List<String> jobTypes; // e.g., ["Full-time", "Part-time"]
  final String? dateRange; // e.g., "Today", "Past 3 Days", "Anytime"
  final String? location;
  final String? salaryRange;

  const JobFilters({
    this.categories = const [],
    this.jobTypes = const [],
    this.dateRange,
    this.location,
    this.salaryRange,
  });

  JobFilters copyWith({
    List<String>? categories,
    List<String>? jobTypes,
    String? dateRange,
    String? location,
    String? salaryRange,
  }) {
    return JobFilters(
      categories: categories ?? this.categories,
      jobTypes: jobTypes ?? this.jobTypes,
      dateRange: dateRange ?? this.dateRange,
      location: location ?? this.location,
      salaryRange: salaryRange ?? this.salaryRange,
    );
  }

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      jobTypes.isNotEmpty ||
      dateRange != null ||
      location != null ||
      salaryRange != null;

  JobFilters clear() {
    return const JobFilters();
  }

  @override
  List<Object?> get props => [categories, jobTypes, dateRange, location, salaryRange];
}

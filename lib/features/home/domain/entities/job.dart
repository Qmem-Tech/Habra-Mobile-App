import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final String id;
  final String title;
  final String companyName;
  final String companyId;
  final String jobType; // e.g., "Full-time", "Part-time"
  final String? description;
  final String? location;
  final String? salary;
  final DateTime? postedDate;

  const Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyId,
    required this.jobType,
    this.description,
    this.location,
    this.salary,
    this.postedDate,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        companyName,
        companyId,
        jobType,
        description,
        location,
        salary,
        postedDate,
      ];
}

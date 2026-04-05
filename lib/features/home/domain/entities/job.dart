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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  /// True when the row was meaningfully edited after creation (for "Updated" badge).
  bool get showAsRecentlyUpdated {
    final c = createdAt;
    final u = updatedAt;
    if (c == null || u == null) return false;
    if (!u.isAfter(c)) return false;
    return u.difference(c) > const Duration(seconds: 90);
  }

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
        createdAt,
        updatedAt,
      ];
}

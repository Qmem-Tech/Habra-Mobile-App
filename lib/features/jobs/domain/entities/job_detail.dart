import 'package:equatable/equatable.dart';

/// Detailed job information entity
class JobDetail extends Equatable {
  final String id;
  final String title;
  final String companyName;
  final String companyId;
  final String? companyLogoUrl;
  final double? companyRating;
  final String jobType; // e.g., "Full-time", "Part-time", "Contract"
  final String? salary; // e.g., "$60k - $80k", "$2k - $3k/week"
  final String? location; // e.g., "Remote / Hybrid", "Seattle, WA"
  final DateTime? postedDate;
  final String? description;
  final List<String> requirements;
  final List<String> benefits;
  final String? category; // e.g., "Homecare", "Trucking", "Retail"
  final bool isFeatured;
  final bool isRemote;
  final double? latitude;
  final double? longitude;

  const JobDetail({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyId,
    this.companyLogoUrl,
    this.companyRating,
    required this.jobType,
    this.salary,
    this.location,
    this.postedDate,
    this.description,
    this.requirements = const [],
    this.benefits = const [],
    this.category,
    this.isFeatured = false,
    this.isRemote = false,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        companyName,
        companyId,
        companyLogoUrl,
        companyRating,
        jobType,
        salary,
        location,
        postedDate,
        description,
        requirements,
        benefits,
        category,
        isFeatured,
        isRemote,
        latitude,
        longitude,
      ];
}

import 'package:equatable/equatable.dart';

/// Job listing entity for list views
class JobListing extends Equatable {
  final String id;
  final String title;
  final String companyName;
  final String? companyLogoUrl;
  final String jobType;
  final String? salary;
  final String? location;
  final DateTime? postedDate;
  final String? category;
  final bool isFeatured;
  final bool isBookmarked;

  const JobListing({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogoUrl,
    required this.jobType,
    this.salary,
    this.location,
    this.postedDate,
    this.category,
    this.isFeatured = false,
    this.isBookmarked = false,
  });

  String get timeAgo {
    if (postedDate == null) return '';
    final now = DateTime.now();
    final difference = now.difference(postedDate!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        companyName,
        companyLogoUrl,
        jobType,
        salary,
        location,
        postedDate,
        category,
        isFeatured,
        isBookmarked,
      ];
}

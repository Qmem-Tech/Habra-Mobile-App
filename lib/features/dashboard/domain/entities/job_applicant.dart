import 'package:equatable/equatable.dart';

enum ApplicantStatus { newApplicant, reviewed }

/// Job applicant summary (list item).
class JobApplicant extends Equatable {
  final String id;
  final String name;
  final String location;
  final String timeAgo;
  final String? bioSnippet;
  final ApplicantStatus status;
  final String? statusLabel;
  final String? statusTimeAgo;

  const JobApplicant({
    required this.id,
    required this.name,
    required this.location,
    required this.timeAgo,
    this.bioSnippet,
    this.status = ApplicantStatus.newApplicant,
    this.statusLabel,
    this.statusTimeAgo,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        timeAgo,
        bioSnippet,
        status,
        statusLabel,
        statusTimeAgo,
      ];
}

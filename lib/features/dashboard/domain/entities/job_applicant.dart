import 'package:equatable/equatable.dart';

enum ApplicantStatus { newApplicant, reviewed }

/// Job applicant summary (list item).
class JobApplicant extends Equatable {
  final String id;
  final String name;
  final String location;
  final String timeAgo;
  final String? bioSnippet;
  final String? avatarUrl;
  final ApplicantStatus status;
  final String? statusLabel;
  final String? statusTimeAgo;
  /// Raw DB status: `pending`, `reviewed`, `shortlisted`, etc.
  final String rawStatus;

  const JobApplicant({
    required this.id,
    required this.name,
    required this.location,
    required this.timeAgo,
    this.bioSnippet,
    this.avatarUrl,
    this.status = ApplicantStatus.newApplicant,
    this.statusLabel,
    this.statusTimeAgo,
    this.rawStatus = 'pending',
  });

  bool get isPending => status == ApplicantStatus.newApplicant;

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        timeAgo,
        bioSnippet,
        avatarUrl,
        status,
        statusLabel,
        statusTimeAgo,
        rawStatus,
      ];
}

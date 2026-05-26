import 'package:equatable/equatable.dart';

/// Single experience entry for applicant.
class ApplicantExperience extends Equatable {
  final String title;
  final String company;
  final String employmentType;
  final String period;
  final String duration;

  const ApplicantExperience({
    required this.title,
    required this.company,
    required this.employmentType,
    required this.period,
    required this.duration,
  });

  @override
  List<Object?> get props => [title, company, employmentType, period, duration];
}

/// Full applicant profile (detail screen).
class ApplicantDetail extends Equatable {
  final String id;
  final String name;
  final String? profileImageUrl;
  /// Optional photo uploaded with the application.
  final String? applicationPhotoUrl;
  final String? email;
  final String? phone;
  final String location;
  final String appliedFor;
  /// Calendar label, e.g. "Oct 12, 2023".
  final String receivedOnLabel;
  /// Relative time since application (optional subtitle).
  final String? appliedAgo;
  /// DB `job_applications.status` e.g. `pending`, `hired`.
  final String applicationStatus;
  final String coverLetter;
  final List<ApplicantExperience> experience;
  final String? resumeFileName;
  final String? resumeFileSize;
  final String? resumeFileUrl;

  const ApplicantDetail({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.applicationPhotoUrl,
    this.email,
    this.phone,
    required this.location,
    required this.appliedFor,
    required this.receivedOnLabel,
    this.appliedAgo,
    this.applicationStatus = 'pending',
    required this.coverLetter,
    required this.experience,
    this.resumeFileName,
    this.resumeFileSize,
    this.resumeFileUrl,
  });

  bool get isTerminalStatus =>
      applicationStatus == 'rejected' || applicationStatus == 'hired';

  @override
  List<Object?> get props => [
        id,
        name,
        profileImageUrl,
        applicationPhotoUrl,
        email,
        phone,
        location,
        appliedFor,
        receivedOnLabel,
        appliedAgo,
        applicationStatus,
        coverLetter,
        experience,
        resumeFileName,
        resumeFileSize,
        resumeFileUrl,
      ];
}

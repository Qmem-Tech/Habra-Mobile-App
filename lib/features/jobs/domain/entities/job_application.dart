import 'package:equatable/equatable.dart';

enum ApplicationStatus {
  pending,
  reviewed,
  shortlisted,
  rejected,
  accepted,
}

/// Job application entity
class JobApplication extends Equatable {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? resumeUrl;
  final String? coverLetter;
  final Map<String, String> screeningAnswers; // question -> answer
  final ApplicationStatus status;
  final DateTime appliedDate;
  final DateTime? reviewedDate;
  final String? notes;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.resumeUrl,
    this.coverLetter,
    this.screeningAnswers = const {},
    required this.status,
    required this.appliedDate,
    this.reviewedDate,
    this.notes,
  });

  bool get isActive => status == ApplicationStatus.pending ||
      status == ApplicationStatus.reviewed ||
      status == ApplicationStatus.shortlisted;

  bool get isClosed => status == ApplicationStatus.rejected ||
      status == ApplicationStatus.accepted;

  @override
  List<Object?> get props => [
        id,
        jobId,
        jobTitle,
        companyName,
        userId,
        fullName,
        email,
        phoneNumber,
        resumeUrl,
        coverLetter,
        screeningAnswers,
        status,
        appliedDate,
        reviewedDate,
        notes,
      ];
}

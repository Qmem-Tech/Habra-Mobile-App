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
  final String location;
  final String appliedFor;
  final String receivedDate;
  final String coverLetter;
  final List<ApplicantExperience> experience;
  final String? resumeFileName;
  final String? resumeFileSize;
  final String? resumeFileUrl;

  const ApplicantDetail({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.location,
    required this.appliedFor,
    required this.receivedDate,
    required this.coverLetter,
    required this.experience,
    this.resumeFileName,
    this.resumeFileSize,
    this.resumeFileUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        profileImageUrl,
        location,
        appliedFor,
        receivedDate,
        coverLetter,
        experience,
        resumeFileName,
        resumeFileSize,
        resumeFileUrl,
      ];
}

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/job_application.dart';

part 'job_application_model.g.dart';

@JsonSerializable()
class JobApplicationModel extends JobApplication {
  const JobApplicationModel({
    required super.id,
    required super.jobId,
    required super.jobTitle,
    required super.companyName,
    required super.userId,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    super.resumeUrl,
    super.coverLetter,
    super.screeningAnswers = const {},
    required super.status,
    required super.appliedDate,
    super.reviewedDate,
    super.notes,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$JobApplicationModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobApplicationModelToJson(this);

  factory JobApplicationModel.fromEntity(JobApplication entity) {
    return JobApplicationModel(
      id: entity.id,
      jobId: entity.jobId,
      jobTitle: entity.jobTitle,
      companyName: entity.companyName,
      userId: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      resumeUrl: entity.resumeUrl,
      coverLetter: entity.coverLetter,
      screeningAnswers: entity.screeningAnswers,
      status: entity.status,
      appliedDate: entity.appliedDate,
      reviewedDate: entity.reviewedDate,
      notes: entity.notes,
    );
  }
}

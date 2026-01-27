// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobApplicationModel _$JobApplicationModelFromJson(Map<String, dynamic> json) =>
    JobApplicationModel(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String,
      companyName: json['companyName'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      resumeUrl: json['resumeUrl'] as String?,
      coverLetter: json['coverLetter'] as String?,
      screeningAnswers:
          (json['screeningAnswers'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, e as String),
              ) ??
              const {},
      status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
      appliedDate: DateTime.parse(json['appliedDate'] as String),
      reviewedDate: json['reviewedDate'] == null
          ? null
          : DateTime.parse(json['reviewedDate'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$JobApplicationModelToJson(
        JobApplicationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'jobId': instance.jobId,
      'jobTitle': instance.jobTitle,
      'companyName': instance.companyName,
      'userId': instance.userId,
      'fullName': instance.fullName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'resumeUrl': instance.resumeUrl,
      'coverLetter': instance.coverLetter,
      'screeningAnswers': instance.screeningAnswers,
      'status': _$ApplicationStatusEnumMap[instance.status]!,
      'appliedDate': instance.appliedDate.toIso8601String(),
      'reviewedDate': instance.reviewedDate?.toIso8601String(),
      'notes': instance.notes,
    };

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.pending: 'pending',
  ApplicationStatus.reviewed: 'reviewed',
  ApplicationStatus.shortlisted: 'shortlisted',
  ApplicationStatus.rejected: 'rejected',
  ApplicationStatus.accepted: 'accepted',
};

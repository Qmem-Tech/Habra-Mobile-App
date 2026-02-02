import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/job_detail.dart';

part 'job_detail_model.g.dart';

@JsonSerializable()
class JobDetailModel extends JobDetail {
  const JobDetailModel({
    required super.id,
    required super.title,
    required super.companyName,
    required super.companyId,
    super.companyLogoUrl,
    super.companyRating,
    required super.jobType,
    super.salary,
    super.location,
    super.postedDate,
    super.description,
    super.requirements = const [],
    super.benefits = const [],
    super.category,
    super.isFeatured = false,
    super.isRemote = false,
    super.latitude,
    super.longitude,
  });

  factory JobDetailModel.fromJson(Map<String, dynamic> json) =>
      _$JobDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobDetailModelToJson(this);

  factory JobDetailModel.fromEntity(JobDetail entity) {
    return JobDetailModel(
      id: entity.id,
      title: entity.title,
      companyName: entity.companyName,
      companyId: entity.companyId,
      companyLogoUrl: entity.companyLogoUrl,
      companyRating: entity.companyRating,
      jobType: entity.jobType,
      salary: entity.salary,
      location: entity.location,
      postedDate: entity.postedDate,
      description: entity.description,
      requirements: entity.requirements,
      benefits: entity.benefits,
      category: entity.category,
      isFeatured: entity.isFeatured,
      isRemote: entity.isRemote,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}

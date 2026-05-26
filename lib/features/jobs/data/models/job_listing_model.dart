import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/job_listing.dart';

part 'job_listing_model.g.dart';

@JsonSerializable()
class JobListingModel extends JobListing {
  const JobListingModel({
    required super.id,
    required super.title,
    required super.companyName,
    super.companyLogoUrl,
    required super.jobType,
    super.salary,
    super.location,
    super.postedDate,
    super.category,
    super.isFeatured = false,
    super.isBookmarked = false,
  });

  factory JobListingModel.fromJson(Map<String, dynamic> json) =>
      _$JobListingModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobListingModelToJson(this);

  factory JobListingModel.fromEntity(JobListing entity) {
    return JobListingModel(
      id: entity.id,
      title: entity.title,
      companyName: entity.companyName,
      companyLogoUrl: entity.companyLogoUrl,
      jobType: entity.jobType,
      salary: entity.salary,
      location: entity.location,
      postedDate: entity.postedDate,
      category: entity.category,
      isFeatured: entity.isFeatured,
      isBookmarked: entity.isBookmarked,
    );
  }
}

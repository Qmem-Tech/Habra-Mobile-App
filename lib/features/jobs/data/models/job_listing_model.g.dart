// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobListingModel _$JobListingModelFromJson(Map<String, dynamic> json) =>
    JobListingModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      companyLogoUrl: json['companyLogoUrl'] as String?,
      jobType: json['jobType'] as String,
      salary: json['salary'] as String?,
      location: json['location'] as String?,
      postedDate: json['postedDate'] == null
          ? null
          : DateTime.parse(json['postedDate'] as String),
      category: json['category'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );

Map<String, dynamic> _$JobListingModelToJson(JobListingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'companyName': instance.companyName,
      'companyLogoUrl': instance.companyLogoUrl,
      'jobType': instance.jobType,
      'salary': instance.salary,
      'location': instance.location,
      'postedDate': instance.postedDate?.toIso8601String(),
      'category': instance.category,
      'isFeatured': instance.isFeatured,
      'isBookmarked': instance.isBookmarked,
    };

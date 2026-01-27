// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobDetailModel _$JobDetailModelFromJson(Map<String, dynamic> json) =>
    JobDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      companyId: json['companyId'] as String,
      companyLogoUrl: json['companyLogoUrl'] as String?,
      companyRating: (json['companyRating'] as num?)?.toDouble(),
      jobType: json['jobType'] as String,
      salary: json['salary'] as String?,
      location: json['location'] as String?,
      postedDate: json['postedDate'] == null
          ? null
          : DateTime.parse(json['postedDate'] as String),
      description: json['description'] as String?,
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: json['category'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isRemote: json['isRemote'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$JobDetailModelToJson(JobDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'companyName': instance.companyName,
      'companyId': instance.companyId,
      'companyLogoUrl': instance.companyLogoUrl,
      'companyRating': instance.companyRating,
      'jobType': instance.jobType,
      'salary': instance.salary,
      'location': instance.location,
      'postedDate': instance.postedDate?.toIso8601String(),
      'description': instance.description,
      'requirements': instance.requirements,
      'benefits': instance.benefits,
      'category': instance.category,
      'isFeatured': instance.isFeatured,
      'isRemote': instance.isRemote,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

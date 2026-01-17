import '../../domain/entities/job.dart';

class JobModel extends Job {
  const JobModel({
    required super.id,
    required super.title,
    required super.companyName,
    required super.companyId,
    required super.jobType,
    super.description,
    super.location,
    super.salary,
    super.postedDate,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      companyId: json['companyId'] as String,
      jobType: json['jobType'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      salary: json['salary'] as String?,
      postedDate: json['postedDate'] != null
          ? DateTime.parse(json['postedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'companyName': companyName,
      'companyId': companyId,
      'jobType': jobType,
      'description': description,
      'location': location,
      'salary': salary,
      'postedDate': postedDate?.toIso8601String(),
    };
  }
}

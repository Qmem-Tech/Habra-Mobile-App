import '../../models/job_application_model.dart';

class MockApplicationsData {
  static final List<JobApplicationModel> _mockApplications = [
    // Empty by default - user hasn't applied yet
  ];

  static List<JobApplicationModel> getMockApplications({
    bool activeOnly = false,
  }) {
    var applications = List<JobApplicationModel>.from(_mockApplications);

    if (activeOnly) {
      applications = applications
          .where((app) => app.isActive)
          .toList();
    } else {
      // Return all applications
    }

    return applications;
  }

  static JobApplicationModel? getApplicationForJob(String jobId) {
    try {
      return _mockApplications.firstWhere(
        (app) => app.jobId == jobId,
      );
    } catch (e) {
      return null;
    }
  }

  static JobApplicationModel addApplication(JobApplicationModel application) {
    _mockApplications.add(application);
    return application;
  }
}

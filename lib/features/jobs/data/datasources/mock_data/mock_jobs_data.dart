import '../../../domain/entities/job_listing.dart';
import '../../models/job_detail_model.dart';
import '../../models/job_listing_model.dart';
import '../../../../../core/resources/app_assets.dart';

class MockJobsData {
  // Available job images - will be rotated/reused
  static const List<String> jobImages = [
    AppAssets.jobsCulturalNightHero,
    AppAssets.jobsCulturalNight,
    AppAssets.jobsTeddyAfroConcert,
  ];

  static String _getJobImage(int index) {
    return jobImages[index % jobImages.length];
  }

  static final List<JobListingModel> _mockJobListings = [
    JobListingModel(
      id: 'job_1',
      title: 'CDL Truck Driver',
      companyName: 'Red Sea Logistics',
      companyLogoUrl: _getJobImage(0),
      jobType: 'Full-time',
      salary: '\$2k - \$3k/week',
      location: 'Seattle, WA',
      postedDate: DateTime.now().subtract(const Duration(hours: 2)),
      category: 'Trucking',
      isFeatured: true,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_2',
      title: 'Personal Care Assistant',
      companyName: 'Selam Home Health',
      companyLogoUrl: _getJobImage(1),
      jobType: 'Full-time',
      salary: '\$22 - \$28/hr',
      location: 'Silver Spring, MD',
      postedDate: DateTime.now().subtract(const Duration(hours: 2)),
      category: 'Homecare',
      isFeatured: false,
      isBookmarked: true,
    ),
    JobListingModel(
      id: 'job_3',
      title: 'Junior Web Developer',
      companyName: 'Habesha Tech Hub',
      companyLogoUrl: _getJobImage(2),
      jobType: 'Contract',
      salary: '\$30/hr + Tips',
      location: 'Remote (US)',
      postedDate: DateTime.now().subtract(const Duration(hours: 5)),
      category: 'Technology',
      isFeatured: false,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_4',
      title: 'Barber',
      companyName: 'Addis Barber Shop',
      companyLogoUrl: _getJobImage(0),
      jobType: 'Part-time',
      salary: 'Commission',
      location: 'Washington, DC',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Retail',
      isFeatured: false,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_5',
      title: 'Senior Graphic Designer',
      companyName: 'Abyssinia Creative',
      companyLogoUrl: _getJobImage(1),
      jobType: 'Full-time',
      salary: '\$60k - \$80k',
      location: 'Remote / Hybrid',
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Design',
      isFeatured: true,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_6',
      title: 'Construction Worker',
      companyName: 'Ethio Builders',
      companyLogoUrl: _getJobImage(2),
      jobType: 'Full-time',
      salary: '\$25 - \$35/hr',
      location: 'Aurora, CO',
      postedDate: DateTime.now().subtract(const Duration(hours: 3)),
      category: 'Construction',
      isFeatured: false,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_7',
      title: 'Home Health Aide',
      companyName: 'Care Plus Services',
      companyLogoUrl: _getJobImage(0),
      jobType: 'Part-time',
      salary: '\$20 - \$25/hr',
      location: 'Washington, DC',
      postedDate: DateTime.now().subtract(const Duration(hours: 6)),
      category: 'Homecare',
      isFeatured: false,
      isBookmarked: false,
    ),
    JobListingModel(
      id: 'job_8',
      title: 'Retail Associate',
      companyName: 'Merkato Market',
      companyLogoUrl: _getJobImage(1),
      jobType: 'Part-time',
      salary: '\$15 - \$18/hr',
      location: 'Silver Spring, MD',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Retail',
      isFeatured: false,
      isBookmarked: false,
    ),
  ];

  static List<JobListing> getMockJobListings({
    String? location,
    List<String>? categories,
    List<String>? jobTypes,
    String? searchQuery,
    bool featuredOnly = false,
  }) {
    var jobs = List<JobListingModel>.from(_mockJobListings);

    // Filter by location
    if (location != null && location.isNotEmpty) {
      jobs = jobs.where((job) {
        if (job.location == null) return false;
        return job.location!.toLowerCase().contains(location.toLowerCase());
      }).toList();
    }

    // Filter by categories
    if (categories != null && categories.isNotEmpty) {
      jobs = jobs.where((job) {
        if (job.category == null) return false;
        return categories.contains(job.category);
      }).toList();
    }

    // Filter by job types
    if (jobTypes != null && jobTypes.isNotEmpty) {
      jobs = jobs.where((job) => jobTypes.contains(job.jobType)).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      jobs = jobs.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query) ||
            (job.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter featured
    if (featuredOnly) {
      jobs = jobs.where((job) => job.isFeatured).toList();
    }

    return jobs;
  }

  static JobDetailModel getJobDetail(String jobId) {
    final job = _mockJobListings.firstWhere(
      (j) => j.id == jobId,
      orElse: () => _mockJobListings.first,
    );

    // Enhanced details for specific jobs
    if (jobId == 'job_5') {
      // Senior Graphic Designer
      return JobDetailModel(
        id: job.id,
        title: job.title,
        companyName: job.companyName,
        companyId: 'company_abyssinia',
        companyLogoUrl: _getJobImage(1),
        companyRating: 4.8,
        jobType: job.jobType,
        salary: job.salary,
        location: job.location,
        postedDate: job.postedDate,
        description:
            'We are seeking a talented Senior Graphic Designer to join our creative team. You will be responsible for creating visually stunning designs that communicate our brand message effectively. This role requires a creative mind, attention to detail, and the ability to work collaboratively with cross-functional teams.',
        requirements: const [
          '3+ years of experience in graphic design or a related field.',
          'Proficiency in Adobe Creative Suite (Photoshop, Illustrator, InDesign).',
          'Fluent in Amharic & English.',
          'Strong portfolio showcasing creative design solutions.',
        ],
        benefits: const [
          'Health Insurance',
          'Annual Bonus',
          'Remote Work',
        ],
        category: job.category,
        isFeatured: job.isFeatured,
        isRemote: true,
        latitude: 9.1450,
        longitude: 38.7617,
      );
    }

    // Default details for other jobs
    // Find the index of this job to get the matching image
    final jobIndex = _mockJobListings.indexWhere((j) => j.id == job.id);
    return JobDetailModel(
      id: job.id,
      title: job.title,
      companyName: job.companyName,
      companyId: 'company_${job.id}',
      companyLogoUrl: jobIndex >= 0 ? _getJobImage(jobIndex) : job.companyLogoUrl,
      companyRating: 4.5,
      jobType: job.jobType,
      salary: job.salary,
      location: job.location,
      postedDate: job.postedDate,
      description:
          'We are looking for a dedicated ${job.title} to join our team. This position offers great opportunities for growth and development.',
      requirements: const [
        'Relevant experience in the field.',
        'Strong communication skills.',
        'Ability to work in a team environment.',
      ],
      benefits: const [
        'Competitive salary',
        'Health benefits',
      ],
      category: job.category,
      isFeatured: job.isFeatured,
      isRemote: job.location?.toLowerCase().contains('remote') ?? false,
    );
  }

  static List<String> getJobCategories() {
    return const [
      'All Jobs',
      'Homecare',
      'Trucking',
      'Retail',
      'Construction',
      'Healthcare',
      'Technology',
      'Design',
    ];
  }

  static List<String> getJobTypes() {
    return const [
      'Full-time',
      'Part-time',
      'Contract',
      'Temporary',
    ];
  }
}

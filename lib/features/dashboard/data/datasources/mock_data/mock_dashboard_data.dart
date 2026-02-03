import '../../../domain/entities/applicant_detail.dart';
import '../../../domain/entities/boost_plan.dart';
import '../../../domain/entities/business_review.dart';
import '../../../domain/entities/dashboard_analytics.dart';
import '../../../domain/entities/dashboard_deal.dart';
import '../../../domain/entities/dashboard_job.dart';
import '../../../domain/entities/job_applicant.dart';
import '../../../domain/repositories/dashboard_repository.dart';

/// Mock data for business owner dashboard (analytics, deals, jobs, reviews, applicants, boost).
class MockDashboardData {
  static const String defaultBusinessId = 'addis-pizza-seattle';

  static DashboardAnalytics getMockAnalytics() {
    final now = DateTime.now();
    final labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final views = [320, 380, 410, 290, 520, 280, 240];
    final points = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DailyViewsPoint(dayLabel: labels[d.weekday % 7], views: views[i]);
    });
    return DashboardAnalytics(
      totalViewsFormatted: '2.4k',
      viewsChangePercent: 15,
      clicksFormatted: '340',
      clicksChangePercent: 5,
      messagesFormatted: '12',
      messagesChangePercent: 2,
      viewsOverTime: points,
      viewsOverTimeSubtitle: 'Past 7 days performance',
      rating: 4.8,
      reviewCount: 120,
      activeDealsCount: 2,
      activeDealsExpiry: 'Expiring in 3 days',
      activeJobsCount: 1,
      activeJobTitle: 'Waitress position',
    );
  }

  static List<DashboardDeal> getMockDeals({DashboardDealStatus? status}) {
    final active = [
      DashboardDeal(
        id: 'd1',
        title: 'Weekend Coffee Special',
        description: 'Valid Sat-Sun • All espresso drinks',
        imageUrl: 'https://picsum.photos/200/200?random=deal1',
        dealTypeLabel: 'Buy 1 Get 1',
        validityDescription: 'Valid Sat-Sun • All espresso drinks',
        redeemedCount: 142,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        status: DashboardDealStatus.active,
      ),
      DashboardDeal(
        id: 'd2',
        title: 'Habesha Platter for Two',
        description: 'Valid Tue-Thu • Dine-in only',
        imageUrl: 'https://picsum.photos/200/200?random=deal2',
        dealTypeLabel: '20% OFF',
        validityDescription: 'Valid Tue-Thu • Dine-in only',
        redeemedCount: 89,
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        status: DashboardDealStatus.active,
      ),
      DashboardDeal(
        id: 'd3',
        title: 'Bulk Spices Discount',
        description: 'Valid in-store only • While stocks last',
        imageUrl: 'https://picsum.photos/200/200?random=deal3',
        dealTypeLabel: 'Clearance',
        validityDescription: 'Valid in-store only • While stocks last',
        redeemedCount: 24,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        status: DashboardDealStatus.active,
      ),
    ];
    final expired = [
      DashboardDeal(
        id: 'd4',
        title: 'Old Promo',
        description: 'Expired',
        imageUrl: 'https://picsum.photos/200/200?random=deal4',
        dealTypeLabel: '10% OFF',
        validityDescription: 'Was valid last month',
        redeemedCount: 56,
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        status: DashboardDealStatus.expired,
      ),
    ];
    final drafts = [
      DashboardDeal(
        id: 'd5',
        title: 'Draft Deal',
        description: 'Not published',
        imageUrl: 'https://picsum.photos/200/200?random=deal5',
        dealTypeLabel: 'Percent Off',
        validityDescription: 'Draft',
        redeemedCount: 0,
        status: DashboardDealStatus.draft,
      ),
    ];
    if (status == null) {
      return [...active, ...expired, ...drafts];
    }
    if (status == DashboardDealStatus.active) return active;
    if (status == DashboardDealStatus.expired) return expired;
    return drafts;
  }

  static List<DashboardJob> getMockJobs() {
    return [
      const DashboardJob(
        id: 'j1',
        title: 'Truck Driver',
        jobType: 'Full-Time',
        location: 'WA',
        salaryDisplay: '100k',
        viewsCount: 142,
        applicantsCount: 12,
        postedTimeAgo: 'Posted 2d ago',
      ),
      const DashboardJob(
        id: 'j2',
        title: 'Barista',
        jobType: 'Part-Time',
        location: 'Addis Ababa',
        salaryDisplay: 'Hourly',
        viewsCount: 89,
        applicantsCount: 4,
        postedTimeAgo: 'Posted 3d ago',
      ),
    ];
  }

  static RatingOverview getMockRatingOverview() {
    return const RatingOverview(
      averageRating: 4.8,
      totalReviews: 124,
      distribution: {5: 90, 4: 25, 3: 6, 2: 2, 1: 1},
    );
  }

  static List<BusinessReview> getMockReviews() {
    return [
      const BusinessReview(
        id: 'r1',
        authorName: 'Abebe Kebede',
        rating: 5,
        text: 'The kitfo was amazing! Best service in town. Definitely coming back for the coffee ceremony next weekend.',
        timeAgo: '2 days ago',
      ),
      const BusinessReview(
        id: 'r2',
        authorName: 'Sara Tadesse',
        rating: 4,
        text: 'Great atmosphere, but parking was tough on Saturday night. The Doro Wat is authentic though!',
        timeAgo: '1 week ago',
        responseText: 'Thanks Sara! We are working on securing a new lot next door. Hope to see you again soon.',
        responseTimeAgo: '5 days ago',
      ),
      const BusinessReview(
        id: 'r3',
        authorName: 'Yared Kassa',
        rating: 2,
        text: 'Food was cold when it arrived. Usually you guys are better than this.',
        timeAgo: '2 weeks ago',
      ),
    ];
  }

  static List<JobApplicant> getMockApplicants(String jobId, {ApplicantStatus? status}) {
    final newList = [
      const JobApplicant(
        id: 'a1',
        name: 'Dawit Bekele',
        location: 'Silver Spring, MD',
        timeAgo: '2h ago',
        bioSnippet: 'I have 3 years of experience working in fast-paced...',
        status: ApplicantStatus.newApplicant,
      ),
      const JobApplicant(
        id: 'a2',
        name: 'Hana Alemu',
        location: 'Seattle, WA',
        timeAgo: '5h ago',
        bioSnippet: 'Barista and customer service background...',
        status: ApplicantStatus.newApplicant,
      ),
    ];
    final reviewed = [
      const JobApplicant(
        id: 'a3',
        name: 'Solomon Tadesse',
        location: 'Portland, OR',
        timeAgo: 'Yesterday',
        status: ApplicantStatus.reviewed,
        statusLabel: 'Interview Scheduled',
        statusTimeAgo: 'Yesterday',
      ),
    ];
    if (status == null) return [...newList, ...reviewed];
    if (status == ApplicantStatus.newApplicant) return newList;
    return reviewed;
  }

  static ApplicantDetail? getMockApplicantDetail(String applicantId) {
    if (applicantId == 'a1' || applicantId == 'abebe') {
      return const ApplicantDetail(
        id: 'abebe',
        name: 'Abebe Kebede',
        location: 'WA',
        appliedFor: 'Barista',
        receivedDate: 'Oct 12, 2023',
        coverLetter: 'I am writing to express my interest in the Barista position at your establishment. '
            'With over 4 years of experience in high-volume coffee shops in Addis Ababa, I have developed '
            'strong skills in espresso preparation, latte art, and customer service. I am passionate about '
            'coffee culture and take pride in creating a welcoming environment for customers. I am reliable, '
            'punctual, and thrive in fast-paced environments. Thank you for considering my application.',
        experience: [
          ApplicantExperience(
            title: 'Senior Waiter & Barista',
            company: 'Kaleb Hotel',
            employmentType: 'Full-time',
            period: 'Jan 2019 - Dec 2022',
            duration: '4 yrs',
          ),
          ApplicantExperience(
            title: 'Cashier',
            company: 'Tomoca Coffee',
            employmentType: 'Part-time',
            period: 'Jun 2018 - Jan 2019',
            duration: '7 mos',
          ),
        ],
        resumeFileName: 'Abebe_Kebede_CV.pdf',
        resumeFileSize: '2.4 MB',
        resumeFileUrl: null,
      );
    }
    return null;
  }

  static List<BoostPlan> getMockBoostPlans() {
    return [
      const BoostPlan(
        id: '1week',
        title: '1 Week Boost',
        description: 'Good for short events',
        priceFormatted: '\$19.99',
        durationWeeks: 1,
      ),
      const BoostPlan(
        id: '1month',
        title: '1 Month Boost',
        description: 'Save 20% vs weekly',
        priceFormatted: '\$49.99',
        originalPriceFormatted: '\$79.96',
        durationWeeks: 4,
      ),
      const BoostPlan(
        id: '3months',
        title: '3 Months Boost',
        description: 'Maximize long-term growth',
        priceFormatted: '\$119.99',
        originalPriceFormatted: '\$239.88',
        durationWeeks: 12,
      ),
    ];
  }
}

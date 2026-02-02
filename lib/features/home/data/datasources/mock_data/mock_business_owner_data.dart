import '../../../domain/entities/business_presence.dart';
import '../../../domain/entities/owner_snapshot_metrics.dart';
import '../../../domain/entities/owner_activity_item.dart';
import '../../../domain/entities/setup_task.dart';
import '../../../domain/entities/listing_status_entity.dart';
import '../../../domain/entities/deal.dart';
import '../../../domain/entities/job.dart';
import '../../models/deal_model.dart';
import '../../models/job_model.dart';

/// Mock data for business owner home flow (single business, all businesses, setup, listing status).
class MockBusinessOwnerData {
  static const String defaultBusinessId = 'addis-pizza-seattle';
  static const String defaultBusinessName = 'Addis Pizza & Grill';

  static List<BusinessPresence> getMockPresences() {
    return [
      BusinessPresence(
        id: 'addis-pizza-seattle',
        name: 'Addis Pizza & Grill',
        locationName: 'Seattle',
        category: 'Cafe/Bistro',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo1',
        isVerified: true,
        isOpenNow: true,
        rating: 4.8,
        reviewCount: 120,
      ),
      BusinessPresence(
        id: 'all',
        name: 'All Businesses',
        category: 'Portfolio Overview',
        imageUrl: 'https://picsum.photos/200/200?random=bo0',
        isVerified: false,
        isOpenNow: true,
      ),
      BusinessPresence(
        id: 'queen-seattle-downtown',
        name: 'Queen of Sheba',
        locationName: 'Seattle Downtown',
        category: 'Restaurant',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo2',
        isVerified: true,
        isOpenNow: true,
        statusText: '4 Open Orders',
        openOrdersCount: 4,
        businessGroupName: 'Queen of Sheba',
      ),
      BusinessPresence(
        id: 'queen-seattle-capitol',
        name: 'Queen of Sheba',
        locationName: 'Seattle Capitol Hill',
        category: 'Restaurant',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo3',
        isVerified: false,
        isOpenNow: false,
        statusText: 'Closed',
        businessGroupName: 'Queen of Sheba',
      ),
      BusinessPresence(
        id: 'queen-portland',
        name: 'Queen of Sheba',
        locationName: 'Portland',
        category: 'Restaurant',
        city: 'Portland',
        state: 'OR',
        imageUrl: 'https://picsum.photos/200/200?random=bo4',
        isVerified: false,
        isOpenNow: true,
        statusText: '12 Open Orders',
        openOrdersCount: 12,
        businessGroupName: 'Queen of Sheba',
      ),
      BusinessPresence(
        id: 'nile-main',
        name: 'Nile Market',
        locationName: 'Main Branch',
        category: 'Grocery',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo5',
        isVerified: false,
        isOpenNow: true,
        statusText: 'Grocery',
        businessGroupName: 'Nile Market',
      ),
    ];
  }

  static OwnerSnapshotMetrics getMockTodaySnapshot() {
    return const OwnerSnapshotMetrics(
      views: 1200,
      clicks: 340,
      messages: 12,
      viewsChangePercent: 15,
      clicksChangePercent: 5,
      messagesChangePercent: -2,
    );
  }

  static OwnerSnapshotMetrics getMockMonthlySnapshot() {
    return const OwnerSnapshotMetrics(
      views: 4200,
      clicks: 980,
      messages: 45,
      viewsChangePercent: 15,
      clicksChangePercent: 5,
      messagesChangePercent: -2,
    );
  }

  static List<OwnerActivityItem> getMockRecentActivity() {
    final now = DateTime.now();
    return [
      OwnerActivityItem(
        id: 'a1',
        type: OwnerActivityType.review,
        title: 'New 5-star review',
        body: '"Best macchiato in the city! The service was..." - Dawit T.',
        authorName: 'Dawit T.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      OwnerActivityItem(
        id: 'a2',
        type: OwnerActivityType.applicant,
        title: 'New Applicant',
        subtitle: 'Selam A. applied for position. B',
        createdAt: now.subtract(const Duration(hours: 5)),
        actionLabel: 'Review',
        actionId: 'app1',
      ),
    ];
  }

  static List<SetupTask> getMockSetupTasks({int completedCount = 1}) {
    return [
      SetupTask(
        id: SetupTaskId.completeProfile,
        title: 'Complete Your Profile',
        description: 'Add your menu, opening hours, and contact de...',
        isCompleted: completedCount > 0,
        isLocked: false,
        actionLabel: 'Continue Setup',
        order: 1,
      ),
      SetupTask(
        id: SetupTaskId.postFirstDeal,
        title: 'Post Your First Deal',
        description: 'Attract new customers with an',
        isCompleted: completedCount > 1,
        isLocked: completedCount < 1,
        order: 2,
      ),
      SetupTask(
        id: SetupTaskId.shareListing,
        title: 'Share Your Listing',
        description: "Let your community know you're here.",
        isCompleted: completedCount > 2,
        isLocked: completedCount < 2,
        order: 3,
      ),
    ];
  }

  static ListingStatusEntity getMockListingStatusPending() {
    return const ListingStatusEntity(
      businessId: 'addis-pizza-seattle',
      businessName: 'Addis Pizza & Grill',
      locationText: 'Addis Ababa, Bole',
      imageUrl: 'https://picsum.photos/200/200?random=listing',
      status: ListingStatusType.pending,
      isNewBusiness: true,
    );
  }

  static ListingStatusEntity getMockListingStatusVerified() {
    return const ListingStatusEntity(
      businessId: 'addis-pizza-seattle',
      businessName: 'Addis Pizza & Grill',
      locationText: 'Addis Ababa, Bole',
      imageUrl: 'https://picsum.photos/200/200?random=listing',
      status: ListingStatusType.verified,
      isNewBusiness: true,
    );
  }

  static List<Deal> getMockOwnerActiveDeals() {
    return [
      DealModel(
        id: 'd1',
        title: 'Buy 1 Get 1 Bunna',
        description: 'Buy one bunna get one free',
        imageUrl: 'https://picsum.photos/200/200?random=deal1',
        businessName: defaultBusinessName,
        businessId: defaultBusinessId,
        discountPercent: 50,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ];
  }

  static List<Job> getMockOwnerJobPosts() {
    return [
      JobModel(
        id: 'j1',
        title: 'Head Chef',
        companyName: defaultBusinessName,
        companyId: defaultBusinessId,
        jobType: 'Full-time',
        location: 'Seattle, WA',
        postedDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// For "Your Businesses" list on All Businesses view (with view count and Manage).
  static List<BusinessPresence> getMockYourBusinessesForPortfolio() {
    return [
      BusinessPresence(
        id: 'addis-pizza-seattle',
        name: 'Addis Pizza & Grill',
        locationName: 'Seattle',
        category: 'Restaurant',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo1',
        isVerified: true,
        isOpenNow: true,
        rating: 4.8,
        reviewCount: 120,
      ),
      BusinessPresence(
        id: 'queen-seattle-downtown',
        name: 'Queen of Sheba',
        locationName: 'Downtown',
        category: 'Restaurant',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo2',
        isVerified: false,
        isOpenNow: true,
        rating: 4.5,
        reviewCount: 80,
      ),
      BusinessPresence(
        id: 'nile-main',
        name: 'Nile Market',
        locationName: 'Main Branch',
        category: 'Grocery',
        city: 'Seattle',
        state: 'WA',
        imageUrl: 'https://picsum.photos/200/200?random=bo5',
        isVerified: false,
        isOpenNow: true,
        rating: 4.2,
        reviewCount: 45,
      ),
    ];
  }
}

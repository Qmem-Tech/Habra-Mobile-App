import '../../../domain/entities/active_boost.dart';
import '../../../domain/entities/boost_location.dart';
import '../../../domain/entities/boost_option.dart';
import '../../../domain/entities/past_boost.dart';

/// Mock data for boosts feature.
class MockBoostsData {
  static List<BoostOption> getBoostOptions() {
    return const [
      BoostOption(
        id: 'business_listing',
        type: BoostOptionType.businessListing,
        priceLabel: 'From \$10/week',
        title: 'My Business Listing',
        description: 'Get featured at the top of search results in the community.',
      ),
      BoostOption(
        id: 'deal',
        type: BoostOptionType.deal,
        priceLabel: 'From \$5/week',
        title: 'A Specific Deal',
        description: 'Promote your offers in the dedicated local Deals section.',
      ),
      BoostOption(
        id: 'job',
        type: BoostOptionType.job,
        priceLabel: 'From \$15/week',
        title: 'A Job Posting',
        description: 'Reach more qualified candidates and fill roles faster.',
      ),
    ];
  }

  static List<BoostLocation> getLocations(String businessId) {
    return const [
      BoostLocation(
        id: 'loc1',
        name: 'Seattle Downtown',
        address: '1201 3rd Ave',
        viewsPerMonth: '2.4k/mo',
        rating: 4.9,
      ),
      BoostLocation(
        id: 'loc2',
        name: 'Seattle Capitol Hill',
        address: 'Broadway & Pike',
        viewsPerMonth: '850/mo',
        rating: 4.5,
      ),
      BoostLocation(
        id: 'loc3',
        name: 'Portland Pearl District',
        address: 'NW 10th Ave',
        viewsPerMonth: '1.1k/mo',
        rating: 4.8,
      ),
      BoostLocation(
        id: 'loc4',
        name: 'Denver LoDo',
        address: '16th St Mall',
        viewsPerMonth: '1.8k/mo',
        rating: 4.6,
      ),
    ];
  }

  static List<ActiveBoost> getActiveBoosts(String businessId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 15);
    final end = DateTime(now.year, now.month, 30);
    return [
      ActiveBoost(
        id: 'active1',
        typeLabel: 'ACTIVE',
        title: 'Premium Business Listing',
        imageUrl: 'https://picsum.photos/400/200?random=boost',
        startDate: start,
        endDate: end,
        views: '1.2k',
        clicks: '348',
        calls: '52',
        viewsChangePercent: 12,
        clicksChangePercent: 8,
        callsChangePercent: 15,
        autoRenew: true,
        planLabel: '1 Month Plan',
      ),
    ];
  }

  static List<PastBoost> getPastBoosts(String businessId) {
    return const [
      PastBoost(
        id: 'past1',
        type: BoostOptionType.job,
        title: 'Featured Job Listing',
        dateRange: 'Sep 01 – Sep 15, 2023',
        views: '842 Views',
      ),
      PastBoost(
        id: 'past2',
        type: BoostOptionType.deal,
        title: 'Deal of the Week',
        dateRange: 'Aug 15 – Aug 22, 2023',
        views: '1.2k Views',
      ),
      PastBoost(
        id: 'past3',
        type: BoostOptionType.businessListing,
        title: 'Storefront Spotlight',
        dateRange: 'Jul 01 – Jul 31, 2023',
        views: '2.1k Views',
      ),
    ];
  }

  static ActiveBoost? getActiveBoostDetail(String boostId) {
    final list = getActiveBoosts('default');
    if (list.isEmpty) return null;
    final b = list.first;
    final now = DateTime.now();
    return ActiveBoost(
      id: b.id,
      typeLabel: b.typeLabel,
      title: b.title,
      imageUrl: b.imageUrl,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 1),
      views: '2,405',
      clicks: '124',
      calls: '12',
      viewsChangePercent: 15,
      clicksChangePercent: 5,
      callsChangePercent: 2,
      autoRenew: false,
      planLabel: '1 Month Plan',
      saves: '8',
      savesChangePercent: 0,
    );
  }
}

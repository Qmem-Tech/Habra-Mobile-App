enum EventCategory {
  all,
  concerts,
  parties,
  cultural,
  music,
  nightlife,
  food,
  networking,
  community,
}

extension EventCategoryExtension on EventCategory {
  String get displayName {
    switch (this) {
      case EventCategory.all:
        return 'All';
      case EventCategory.concerts:
        return 'Concerts';
      case EventCategory.parties:
        return 'Parties';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.music:
        return 'Music';
      case EventCategory.nightlife:
        return 'Nightlife';
      case EventCategory.food:
        return 'Food';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.community:
        return 'Community';
    }
  }
}

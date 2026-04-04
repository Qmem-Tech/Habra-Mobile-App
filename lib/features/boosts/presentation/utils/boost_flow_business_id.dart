import '../../../home/presentation/bloc/business_owner_home_state.dart';

/// Business id for boost wizard APIs — same anchor as Boosts/Dashboard when "All" is selected.
String? focusBusinessIdForBoostFlows(BusinessOwnerHomeState homeState) {
  if (homeState is! BusinessOwnerHomeLoaded) return null;
  final id = homeState.focusBusinessIdForOwnerTools;
  if (id == null || id.isEmpty) return null;
  return id;
}

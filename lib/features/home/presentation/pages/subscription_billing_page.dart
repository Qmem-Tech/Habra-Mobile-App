import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_subscription_cubit.dart';
import 'business_owner_subscription_page.dart';

/// Subscription and billing entry point from the owner profile (RevenueCat / paywall).
class SubscriptionBillingPage extends StatelessWidget {
  const SubscriptionBillingPage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    BusinessOwnerSubscriptionCubit? existing;
    try {
      existing = context.read<BusinessOwnerSubscriptionCubit>();
    } catch (_) {
      existing = null;
    }
    if (existing != null) {
      return BlocProvider.value(
        value: existing,
        child: BusinessOwnerSubscriptionPage(user: user),
      );
    }
    return BlocProvider(
      create: (_) => di.sl<BusinessOwnerSubscriptionCubit>()..refresh(user.id),
      child: BusinessOwnerSubscriptionPage(user: user),
    );
  }
}

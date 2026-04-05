import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_subscription_cubit.dart';
import 'business_owner_subscription_page.dart';

/// Subscription and billing entry point from the owner profile (RevenueCat / paywall).
class SubscriptionBillingPage extends StatelessWidget {
  const SubscriptionBillingPage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<BusinessOwnerSubscriptionCubit>(),
      child: BusinessOwnerSubscriptionPage(user: user),
    );
  }
}

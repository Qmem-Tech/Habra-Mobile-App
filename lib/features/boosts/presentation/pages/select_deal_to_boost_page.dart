import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart';
import '../../../dashboard/domain/entities/dashboard_deal.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/pages/boost_listing_page.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/deal_selection_card.dart';

class SelectDealToBoostPage extends StatefulWidget {
  const SelectDealToBoostPage({super.key});

  @override
  State<SelectDealToBoostPage> createState() => _SelectDealToBoostPageState();
}

class _SelectDealToBoostPageState extends State<SelectDealToBoostPage> {
  @override
  void initState() {
    super.initState();
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      context.read<BoostsCubit>().loadDeals(homeState.selectedPresence!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Deal to Boost',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<BoostsCubit, BoostsState>(
        builder: (context, state) {
          if (state is! BoostDealsLoaded) {
            return const HabraCircularLoader(fullScreen: true);
          }
          final deals = state.deals;
          final selectedId = state.selectedId;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppResources.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which deal do you want to boost?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select an active deal from your list below to start a boosting campaign.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return DealSelectionCard(
                      deal: deal,
                      isSelected: selectedId == deal.id,
                      onTap: () => context.read<BoostsCubit>().selectDeal(deal.id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppResources.spacingM),
                child: AppButton(
                  text: 'Continue',
                  onPressed: selectedId != null
                      ? () => _continueWithDeal(context, deals, selectedId)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _continueWithDeal(
    BuildContext context,
    List<DashboardDeal> deals,
    String selectedId,
  ) {
    DashboardDeal? selected;
    for (final d in deals) {
      if (d.id == selectedId) {
        selected = d;
        break;
      }
    }
    if (selected == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<DashboardCubit>(),
          child: BoostListingPage(
            boostType: 'deal',
            selectedId: selected?.id,
            selectedTitle: selected?.title,
            dealImageUrl: selected?.imageUrl,
            dealMerchantName: selected?.merchantName,
            dealExpiresInDays: selected?.expiresInDays,
          ),
        ),
      ),
    );
  }
}

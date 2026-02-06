import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../domain/entities/boost_option.dart';
import '../bloc/boosts_cubit.dart';
import '../bloc/boosts_state.dart';
import '../widgets/boost_option_card.dart';
import 'select_location_page.dart';
import 'select_deal_to_boost_page.dart';
import 'select_job_to_boost_page.dart';

/// "What would you like to boost?" – Business Listing, Deal, or Job.
class BoostOptionsPage extends StatefulWidget {
  const BoostOptionsPage({super.key});

  @override
  State<BoostOptionsPage> createState() => _BoostOptionsPageState();
}

class _BoostOptionsPageState extends State<BoostOptionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BoostsCubit>().loadBoostOptions();
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
          'Boost Options',
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
          if (state is! BoostOptionsLoaded) {
            return const HabraCircularLoader(fullScreen: true);
          }
          final options = state.options;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to boost?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                ...options.map(
                  (option) => BoostOptionCard(
                    option: option,
                    onTap: () => _onOptionTap(context, option),
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                _buildProTip(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.brandPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Boosting increases your visibility among the local Habesha community. Most owners start with Business Listing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onOptionTap(BuildContext context, BoostOption option) {
    switch (option.type) {
      case BoostOptionType.businessListing:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectLocationPage(),
            ),
          ),
        );
        break;
      case BoostOptionType.deal:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectDealToBoostPage(),
            ),
          ),
        );
        break;
      case BoostOptionType.job:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BoostsCubit>(),
              child: const SelectJobToBoostPage(),
            ),
          ),
        );
        break;
    }
  }
}

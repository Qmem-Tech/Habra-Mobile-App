import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/deals_cubit.dart';
import '../bloc/deals_state.dart';

class RedeemDealPage extends StatelessWidget {
  final String dealId;

  const RedeemDealPage({super.key, required this.dealId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = di.sl<DealsCubit>();
        cubit.redeemDeal(dealId);
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Redeem Deal'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<DealsCubit, DealsState>(
          builder: (context, state) {
            if (state is RedeemDealLoading) {
              return const HabraCircularLoader(fullScreen: true);
            }

            if (state is RedeemDealError) {
              return _buildErrorView(context, state.message);
            }

            if (state is RedeemDealLoaded) {
              return _buildContent(context, state.deal, state.redemptionCode);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic deal, String redemptionCode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDealInfo(deal),
          const SizedBox(height: 24),
          _buildQRCode(redemptionCode),
          const SizedBox(height: 24),
          _buildRedemptionCode(redemptionCode),
          const SizedBox(height: 16),
          _buildInstructions(),
          const SizedBox(height: 32),
          _buildActionButtons(context, deal),
        ],
      ),
    );
  }

  Widget _buildDealInfo(dynamic deal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              deal.business.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: AppColors.backgroundGrey,
                  child: const Icon(Icons.store, size: 24, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Sat, Dec 12 • 8:00 PM',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      deal.business.fullAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode(String code) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: code,
        version: QrVersions.auto,
        size: 250,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRedemptionCode(String code) {
    return Column(
      children: [
        const Text(
          'Redemption Code',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          code,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Present this code to the cashier at checkout to claim your discount.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic deal) {
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            text: 'Directions',
            onPressed: () {
              // Handle directions
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: 'Call Business',
            icon: Icons.phone,
            onPressed: () {
              // Handle call
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

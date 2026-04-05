import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/deal.dart';
import '../bloc/deals_cubit.dart';
import '../bloc/deals_state.dart';
import '../widgets/deal_network_image.dart';

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
              return _buildContent(
                context,
                state.deal,
                state.redemptionCode,
                state.redemptionId,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Deal deal,
    String redemptionCode,
    String redemptionId,
  ) {
    final qrPayload = jsonEncode({
      'id': redemptionId,
      'code': redemptionCode,
      'dealId': deal.id,
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDealInfo(deal),
          const SizedBox(height: 24),
          _buildQRCode(qrPayload),
          const SizedBox(height: 16),
          _buildRedemptionCode(redemptionCode),
          const SizedBox(height: 8),
          _buildRedemptionIdRow(context, redemptionId),
          const SizedBox(height: 24),
          _buildInstructions(),
          const SizedBox(height: 32),
          _buildActionButtons(context, deal),
        ],
      ),
    );
  }

  Widget _buildDealInfo(Deal deal) {
    final expiresLine = deal.expiresAt != null
        ? DateFormat('EEE, MMM d • h:mm a').format(deal.expiresAt!.toLocal())
        : 'See deal for validity';

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
            child: DealNetworkImage(
              imageUrl: deal.business.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
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
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expiresLine,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        deal.business.fullAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildQRCode(String data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
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
          'Redemption code',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          code,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRedemptionIdRow(BuildContext context, String redemptionId) {
    return Column(
      children: [
        const Text(
          'Proof ID (for staff / support)',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          redemptionId,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.textSecondary,
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: redemptionId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proof ID copied')),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy proof ID'),
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
        'Show the QR code or say the redemption code at checkout. '
        'Staff can confirm the redemption in their dashboard or by looking up the proof ID in Supabase (deal_redemptions). '
        'Each account can redeem this deal once.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _openMaps(Deal deal) async {
    final q = deal.business.fullAddress.trim();
    if (q.isEmpty) return;
    final encoded = Uri.encodeComponent(q);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callBusiness(Deal deal) async {
    final raw = deal.business.phone?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.parse('tel:$raw');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildActionButtons(BuildContext context, Deal deal) {
    final hasPhone =
        deal.business.phone != null && deal.business.phone!.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            text: 'Directions',
            onPressed: () => _openMaps(deal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: 'Call',
            icon: Icons.phone,
            onPressed: hasPhone ? () => _callBusiness(deal) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
      ),
    );
  }
}

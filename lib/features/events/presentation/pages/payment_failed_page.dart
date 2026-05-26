import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/order.dart' as events;
import 'my_tickets_page.dart';

class PaymentFailedPage extends StatelessWidget {
  final String message;
  final events.Order? order;

  /// True when Stripe succeeded but the order is still `processing` (webhook / DB lag).
  final bool awaitingConfirmation;

  const PaymentFailedPage({
    super.key,
    required this.message,
    this.order,
    this.awaitingConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = awaitingConfirmation ? 'Confirming your order' : 'Payment Failed';
    final leadIcon = awaitingConfirmation ? Icons.hourglass_top : Icons.wallet;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadIcon,
                  size: 64,
                  color: awaitingConfirmation ? AppColors.brandPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (awaitingConfirmation) ...[
                AppButton(
                  text: 'Check My Tickets',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MyTicketsPage(initialUpcoming: false),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppOutlinedButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ] else ...[
                AppButton(
                  text: 'Try Again',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
                AppOutlinedButton(
                  text: 'Use Different Card',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
                AppOutlinedButton(
                  text: 'Check My Tickets',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyTicketsPage(initialUpcoming: false),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppOutlinedButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.brandPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

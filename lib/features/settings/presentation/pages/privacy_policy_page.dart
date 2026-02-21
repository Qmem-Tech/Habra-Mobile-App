import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';

/// Privacy Policy static content page.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppResources.spacingL,
          vertical: AppResources.spacingM,
        ),
        children: [
          Text(
            'Your privacy is important to us. This Privacy Policy explains how the Habesha Community Super App collects, uses, and protects your personal information to help you stay connected with your community.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppResources.spacingL),
          _Section(
            title: '1. Information We Collect',
            items: [
              'Account Info: Your name, email address, phone number, and the city you select (e.g., Seattle, DC, Atlanta) when you sign up.',
              'Business/Employer Info: If you list a business or post a job, we collect professional details, including business name, category, and contact information.',
              'Location Data: We collect your approximate location to show you the nearest Habesha restaurants, services, and local community events.',
              'Usage Data: Your in-app actions, such as businesses you favorite, events you view, and job applications you submit.',
              'Communication: Messages sent within city-based community chat rooms to ensure a safe and respectful environment.',
            ],
          ),
          _Section(
            title: '2. How We Use Your Information',
            items: [
              'Localization: To provide a personalized dashboard based on your city.',
              'Service Delivery: To process ticket purchases and manage your "Verified" business status.',
              'Notifications: To send you updates on community events, new job postings in your industry, or cultural holiday announcements.',
              'Security: To detect and prevent fraudulent listings or community guideline violations.',
            ],
          ),
          _Section(
            title: '3. Payments & Financial Security',
            items: [
              'All financial transactions for event tickets and business "Boosts" are processed securely through Stripe.',
              'The Habesha Community Super App does not store your full credit card or bank account details on our servers.',
              'Payment information is encrypted and handled entirely by our secure payment partner.',
            ],
          ),
          _Section(
            title: '4. Sharing Your Information',
            items: [
              'We do not sell your personal data. We may share limited data only in the following cases:',
              'Event Organizers: When you buy a ticket, your name may be shared with the promoter for check-in purposes.',
              'Service Providers: With trusted partners like Stripe (for payments) and Google Maps (for location services).',
              'Legal Requirements: If required by law to protect the safety of our community members.',
            ],
          ),
          _Section(
            title: '5. Data Security',
            items: [
              'We use industry-standard encryption and secure servers to keep your community profile safe. However, no system is 100% secure. We encourage you to use strong passwords and keep your login credentials private.',
            ],
          ),
          _Section(
            title: '6. Your Rights',
            items: [
              'You have the right to access, update, or delete your personal information at any time through your Profile Settings. By using the app, you consent to our data practices designed to provide you with the best community experience.',
            ],
          ),
          _Section(
            title: '7. Children\'s Privacy',
            items: [
              'The Habesha Community Super App is intended for users aged 13 and older. We do not knowingly collect personal data from children under this age. Users must be 18+ to list businesses or post employment opportunities.',
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppResources.spacingL),
      child: Container(
        padding: const EdgeInsets.all(AppResources.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppResources.spacingS),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppResources.spacingS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

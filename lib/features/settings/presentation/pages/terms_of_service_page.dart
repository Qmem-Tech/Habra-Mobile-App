import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';

/// Terms of Service static content page.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
            'The Habesha Community Super App provides a unified platform for the Ethiopian and Eritrean diaspora to connect with local businesses, events, and job opportunities. By using the app, you agree to the following:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppResources.spacingL),
          _Section(
            title: 'Eligibility',
            items: [
              'You must be at least 18 years old to post business listings or job opportunities.',
              'One account per user. Duplicate or fake profiles used to manipulate ratings or community chats may be suspended.',
            ],
          ),
          _Section(
            title: 'Service Mechanics',
            items: [
              'Business Directory: Users can browse and contact local services (Restaurants, Trucking, Homecare, etc.). The app is a directory and is not responsible for the quality of services provided by third parties.',
              'Job Board: Employers are responsible for the accuracy of job descriptions. The app does not vet individual applicants or employers.',
              'Events: Users can discover and purchase tickets for community concerts, cultural holidays, and social gatherings.',
            ],
          ),
          _Section(
            title: 'Ticketing & Payments',
            items: [
              'All ticket purchases are processed securely via Stripe.',
              'Once a ticket is purchased, a unique QR Code is generated in the \'My Tickets\' section for event entry.',
              'Refund policies are determined by the individual Event Promoter. The Habesha Community Super App acts only as the ticketing technology provider.',
            ],
          ),
          _Section(
            title: 'Community & Chat Rooms',
            items: [
              'City-based chat rooms (Seattle, DC, Atlanta, etc.) are for community networking and local news.',
              'Respect is mandatory. Harassment, hate speech, or the sharing of illegal content will lead to an immediate and permanent account ban.',
              'No spamming. Repeatedly posting the same advertisement in community chats is prohibited.',
            ],
          ),
          _Section(
            title: 'Boosts & Premium Features',
            items: [
              'Business owners may purchase Boosted Listings or Premium Badges to increase visibility.',
              'These digital promotions are non-refundable once activated.',
              '\'Verified\' badges are granted at the discretion of the administration to businesses that meet our community trust standards.',
            ],
          ),
          _Section(
            title: 'Fair Play & Security',
            items: [
              'Any attempt to scrape data, automate posts, or exploit the app\'s API will result in legal action and a platform ban.',
              'Users are responsible for maintaining the security of their login credentials.',
            ],
          ),
          _Section(
            title: 'Privacy & Data',
            items: [
              'By using the app, you agree to our localized data practices. We use your city selection to show you relevant nearby content.',
              'Your payment data is handled by Stripe and is never stored on our private servers.',
              'Refer to our full Privacy Policy for more details on how we protect the community.',
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

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';

/// Community Guidelines static content page.
class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
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
            'The Habesha Community Super App is a space for connection, celebration, and growth. To keep our community safe and professional, all users must follow these guidelines:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppResources.spacingL),
          _Section(
            title: 'Respect & Culture',
            items: [
              'Celebrate Diversity: Our community is diverse. Treat all members with the respect and kindness our culture is known for.',
              'Zero Tolerance for Hate: Harassment, discrimination, or hate speech based on ethnicity, religion, or gender will result in an immediate and permanent ban.',
              'Maintain Decorum: Avoid aggressive language or "flaming" in public chat rooms.',
            ],
          ),
          _Section(
            title: 'Authentic Listings',
            items: [
              'Be Truthful: Whether you are listing a restaurant, a trucking service, or a job opening, all information must be accurate and up-to-date.',
              'No Scams: Posting fraudulent services, fake event tickets, or deceptive job offers is strictly prohibited.',
              'Verified Status: Do not attempt to impersonate a "Verified" business or community leader.',
            ],
          ),
          _Section(
            title: 'City Chat Etiquette',
            items: [
              'Stay on Topic: Use city-specific rooms (e.g., #Seattle, #DC) for local news, networking, and community questions.',
              'No Spamming: Do not post the same advertisement or message repeatedly. If you want to promote a business, please use the "Business Directory" or purchase a "Boost."',
              'Private Stays Private: Do not share other people\'s private phone numbers or home addresses without their explicit consent.',
            ],
          ),
          _Section(
            title: 'Job Board & Professionalism',
            items: [
              'Fair Hiring: Employers must provide clear details regarding job roles, requirements, and contact methods.',
              'Professional Conduct: Users applying for jobs should maintain a professional tone when communicating with local business owners.',
            ],
          ),
          _Section(
            title: 'Safety & Reporting',
            items: [
              'Protect Your Data: Never share your password or financial information in a chat room.',
              'See Something, Say Something: Use the "Report" button on any post, business listing, or message that violates these rules. Our admin team reviews reports daily.',
              'Self-Promotion: While we support community growth, excessive self-promotion in the wrong categories may lead to content removal.',
            ],
          ),
          _Section(
            title: 'Enforcement',
            items: [
              'Warnings: For minor first-time offenses, users may receive a formal warning.',
              'Suspensions: Repeated violations or spamming will result in a temporary account suspension.',
              'Permanent Bans: Severe violations—including hate speech, fraud, or illegal activity—will lead to a permanent ban of your account and device ID.',
            ],
          ),
          _Section(
            title: 'Changes to Guidelines',
            items: [
              'The Habesha Community Super App reserves the right to update these rules as our community grows. We are committed to keeping this a high-quality, trusted space for all Ethiopians and Eritreans in the diaspora.',
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

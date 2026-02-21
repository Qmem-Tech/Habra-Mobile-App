import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About Us page with app description and social links.
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String _paragraph1 =
      'The Habesha Community Super App is more than just a directory—it\'s a fresh, modern, and powerful way to experience our community in the diaspora.';
  static const String _paragraph2 =
      'We built this app for the Habesha family who want unity. No more searching through scattered WhatsApp groups. No more missing out on local events. Just pure connection, trusted business growth, and daily cultural convenience.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
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
            _paragraph1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppResources.spacingM),
          Text(
            _paragraph2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppResources.spacingXL),
          Text(
            'Links',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppResources.spacingM),
          _SocialLink(
            icon: Icons.facebook,
            label: 'Facebook',
            onTap: () => _launchUrl('https://facebook.com'),
          ),
          _SocialLink(
            icon: Icons.camera_alt,
            label: 'Instagram',
            onTap: () => _launchUrl('https://instagram.com'),
          ),
          _SocialLink(
            icon: Icons.music_note,
            label: 'Tiktok',
            onTap: () => _launchUrl('https://tiktok.com'),
          ),
          _SocialLink(
            icon: Icons.alternate_email,
            label: 'X',
            onTap: () => _launchUrl('https://x.com'),
          ),
          _SocialLink(
            icon: Icons.forum,
            label: 'Reddit',
            onTap: () => _launchUrl('https://reddit.com'),
          ),
          _SocialLink(
            icon: Icons.sports_esports,
            label: 'Discord',
            onTap: () => _launchUrl('https://discord.com'),
          ),
          const SizedBox(height: AppResources.spacingXL),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppResources.spacingM,
                    vertical: AppResources.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey.withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppResources.radiusXXL),
                  ),
                  child: Text(
                    'v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppResources.spacingM),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius:
                      BorderRadius.circular(AppResources.radiusM),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppResources.spacingM),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

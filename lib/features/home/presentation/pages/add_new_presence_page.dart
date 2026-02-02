import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import 'business_details_step1_page.dart';

/// Add New Presence: choose New Business or New Location, then Continue.
class AddNewPresencePage extends StatefulWidget {
  const AddNewPresencePage({super.key});

  @override
  State<AddNewPresencePage> createState() => _AddNewPresencePageState();
}

class _AddNewPresencePageState extends State<AddNewPresencePage> {
  bool _isNewBusiness = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Presence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'What would you like to list on Habra today?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              _buildOptionCard(
                title: 'New Business',
                description:
                    'Create a profile for a completely new brand or company.',
                example: 'Ex: Opening your first coffee shop.',
                iconPath: AppAssets.businessOwnerNewBusiness,
                isSelected: _isNewBusiness,
                radioValue: true,
                onTap: () => setState(() => _isNewBusiness = true),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                title: 'New Location',
                description:
                    'Add a new branch or outlet to a business you already manage.',
                example: 'Ex: Adding a second location for \'Habesha Market\'.',
                iconPath: AppAssets.businessOwnerNewLocation,
                isSelected: !_isNewBusiness,
                radioValue: false,
                onTap: () => setState(() => _isNewBusiness = false),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Continue',
            onPressed: () => _onContinue(context),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required String example,
    required String iconPath,
    required bool isSelected,
    required bool radioValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppResources.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppResources.spacingL),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          color: AppColors.backgroundWhite,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              child: Image.asset(
                iconPath,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.store, color: AppColors.brandPrimary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    example,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RadioStyleIndicator(isSelected: isSelected),
          ],
        ),
      ),
    );
  }

  void _onContinue(BuildContext context) {
    if (_isNewBusiness) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BusinessDetailsStep1Page(),
        ),
      );
    } else {
      // TODO: Navigate to "Select existing business" then location step
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BusinessDetailsStep1Page(),
        ),
      );
    }
  }
}

/// Custom selection indicator (replaces deprecated Radio for visual only; card handles tap).
class _RadioStyleIndicator extends StatelessWidget {
  final bool isSelected;

  const _RadioStyleIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
          width: 2,
        ),
        color: isSelected ? AppColors.brandPrimary : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
          : null,
    );
  }
}

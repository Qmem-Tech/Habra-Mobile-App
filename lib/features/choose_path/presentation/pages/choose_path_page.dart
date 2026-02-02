import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/pages/sign_up_options_page.dart';
import '../../../auth/presentation/pages/business_sign_in_page.dart';
import '../bloc/choose_path_cubit.dart';

class ChoosePathPage extends StatelessWidget {
  const ChoosePathPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChoosePathCubit(),
      child: const _ChoosePathView(),
    );
  }
}

class _ChoosePathView extends StatefulWidget {
  const _ChoosePathView();

  @override
  State<_ChoosePathView> createState() => _ChoosePathViewState();
}

class _ChoosePathViewState extends State<_ChoosePathView> {
  UserRole? _selectedRole = UserRole.customer; // Default to Community Member

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _onSelect() {
    if (_selectedRole == null) return;
    final role = _selectedRole!;
    if (role == UserRole.businessOwner) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessSignInPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SignUpOptionsPage(selectedRole: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Choose your path',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppResources.spacingS),

              // Description
              Text(
                'Select how you want to connect with the Habesha community.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppResources.spacingXL),

              // Community Member Card
              _buildRoleCard(
                role: UserRole.customer,
                title: 'Community Member',
                description: 'Select how you want to connect with the Habesha community.',
                icon: Icons.person,
                isSelected: _selectedRole == UserRole.customer,
                onTap: () => _onRoleSelected(UserRole.customer),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Business Owner Card
              _buildRoleCard(
                role: UserRole.businessOwner,
                title: 'Business Owner',
                description: 'List your services, manage bookings, and reach new customers.',
                icon: Icons.store,
                isSelected: _selectedRole == UserRole.businessOwner,
                onTap: () => _onRoleSelected(UserRole.businessOwner),
              ),
              const SizedBox(height: AppResources.spacingL),

              // Warning Note
              _buildWarningNote(),
              const SizedBox(height: AppResources.spacingXL),

              // Select Button
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _onSelect : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.backgroundGrey,
                    disabledForegroundColor: AppColors.textTertiary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Select',
                    style: AppFonts.button(color: AppColors.textOnPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey;
    final iconBackgroundColor = isSelected ? AppColors.brandSecondary : AppColors.backgroundGrey;
    final iconColor = isSelected ? AppColors.textOnPrimary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppResources.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppResources.spacingL),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          color: AppColors.backgroundWhite,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppResources.iconSizeL,
              ),
            ),
            const SizedBox(width: AppResources.spacingL),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppResources.spacingXS),
                  Text(
                    description,
                    style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningNote() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD), // Light yellow background
        borderRadius: BorderRadius.circular(AppResources.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning icon - styled as triangle-like
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6F00), // Dark orange
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppResources.spacingM),
          // Warning text
          Expanded(
            child: Text(
              'Note: Your account type cannot be changed after registration.',
              style: AppFonts.bodySmall(
                color: const Color(0xFFFF6F00), // Dark orange text
              ),
            ),
          ),
        ],
      ),
    );
  }
}

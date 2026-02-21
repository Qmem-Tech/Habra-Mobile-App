import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import '../../../profile/presentation/bloc/edit_profile_state.dart';

/// Edit Profile: full name, email (read-only), phone, location, bio. Save updates via [EditProfileCubit].
class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController();
    _locationController = TextEditingController(text: 'Washington, D.C.');
    _bioController = TextEditingController(
      text: 'Coffee lover, tech enthusiast, and proud Habesha connecting with my roots.',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    context.read<EditProfileCubit>().saveProfile(
          widget.user.id,
          UserProfileUpdate(
            fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileSaveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated'),
              backgroundColor: AppColors.success,
            ),
          );
          if (!context.mounted) return;
          Navigator.pop(context);
        }
        if (state is EditProfileSaveError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final saving = state is EditProfileSaving;
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            title: const Text('Edit Profile'),
            backgroundColor: AppColors.backgroundWhite,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: saving ? null : () => _save(context),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingL),
            child: Column(
              children: [
                const SizedBox(height: AppResources.spacingM),
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Change Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                  ),
                ),
                const SizedBox(height: AppResources.spacingXL),
                _LabeledField(
                    label: 'Full Name',
                    child: TextField(controller: _nameController)),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                    label: 'Email Address',
                    child: TextField(
                        controller: _emailController, readOnly: true)),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                    label: 'Phone Number',
                    child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone)),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Location',
                  child: TextField(controller: _locationController),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Bio',
                  child: TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 160,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppResources.spacingXS),
        child,
      ],
    );
  }
}

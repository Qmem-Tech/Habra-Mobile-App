import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/widgets/location_picker_bottom_sheet.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import '../../../profile/presentation/bloc/edit_profile_state.dart';

/// Edit Profile: full name, email (read-only), phone, location, bio, photo upload. Save via [EditProfileCubit].
class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  String _phoneNumber = '';
  String _initialPhoneNumber = '';
  bool _profileLoadTriggered = false;
  bool _hasPrefilledFromProfile = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _locationController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadTriggered) {
      _profileLoadTriggered = true;
      context.read<EditProfileCubit>().loadProfile(widget.user.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required')),
      );
      return;
    }
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters')),
      );
      return;
    }
    context.read<EditProfileCubit>().saveProfile(
          widget.user.id,
          UserProfileUpdate(
            fullName: name,
            phone: _phoneNumber.isEmpty ? null : _phoneNumber,
            bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          ),
        );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file == null || !context.mounted) return;
    context.read<EditProfileCubit>().uploadPhoto(widget.user.id, file);
  }

  Future<void> _openLocationPicker() async {
    final result = await LocationPickerBottomSheet.show(
      context,
      currentValue: _locationController.text.trim(),
    );
    if (result != null && mounted) {
      setState(() => _locationController.text = result);
    }
  }

  void _prefillFromProfile(UserProfile profile) {
    if (_hasPrefilledFromProfile) return;
    _hasPrefilledFromProfile = true;
    setState(() {
      if (profile.location != null && profile.location!.isNotEmpty) {
        _locationController.text = profile.location!;
      }
      if (profile.bio != null && profile.bio!.isNotEmpty) {
        _bioController.text = profile.bio!;
      }
      if (profile.phone != null && profile.phone!.isNotEmpty) {
        _phoneNumber = profile.phone!;
        _initialPhoneNumber = profile.phone!;
      }
      _avatarUrl = profile.avatarUrl;
    });
  }

  /// Strips a leading country code (e.g. "+1") so `IntlPhoneField` can handle
  /// the national part. Returns only digits after the first country-code group.
  String _stripCountryCode(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && phone.startsWith('+')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileLoaded) {
          _prefillFromProfile(state.profile);
        }
        if (state is EditProfileSaveSuccess) {
          _avatarUrl = state.profile.avatarUrl;
          final auth = context.read<AuthCubit>().state;
          if (auth is AuthAuthenticated) {
            final u = auth.user;
            final updated = User(
              id: u.id,
              email: u.email,
              name: state.profile.fullName,
              role: u.role,
              avatarUrl: state.profile.avatarUrl,
            );
            context.read<AuthCubit>().applyProfileEditsToSession(updated);
          }
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
        final loadedProfile = state is EditProfileLoaded ? state.profile : null;
        final displayAvatarUrl = _avatarUrl ?? loadedProfile?.avatarUrl;

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
                  backgroundImage: displayAvatarUrl != null && displayAvatarUrl.isNotEmpty
                      ? NetworkImage(displayAvatarUrl)
                      : null,
                  child: displayAvatarUrl == null || displayAvatarUrl.isEmpty
                      ? Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppResources.spacingM),
                OutlinedButton.icon(
                  onPressed: saving ? null : () => _pickAndUploadPhoto(context),
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
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Email Address',
                  child: TextField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      suffixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Phone Number',
                  child: IntlPhoneField(
                    disableLengthCheck: true,
                    initialValue: _stripCountryCode(_initialPhoneNumber),
                    initialCountryCode: 'US',
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (PhoneNumber phone) {
                      _phoneNumber = phone.completeNumber;
                    },
                    validator: (PhoneNumber? phone) {
                      if (phone == null || phone.number.isEmpty) return null;
                      final digits = phone.completeNumber.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Location',
                  child: GestureDetector(
                    onTap: saving ? null : _openLocationPicker,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _locationController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Select your city...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Bio',
                  child: TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 160,
                    decoration: const InputDecoration(
                      hintText: 'Tell us a little about yourself...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(14),
                    ),
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

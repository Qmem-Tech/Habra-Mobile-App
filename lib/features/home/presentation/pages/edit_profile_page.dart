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
import '../../../auth/presentation/pages/interests_selection_page.dart';
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
  List<String> _selectedInterests = const [];

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
            interests: _selectedInterests,
          ),
        );
  }

  Future<void> _openInterestsEditor() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => InterestsSelectionPage(
          onboardingFlow: false,
          initialSelected: _selectedInterests,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _selectedInterests = result);
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
      if (profile.fullName.trim().isNotEmpty) {
        _nameController.text = profile.fullName.trim();
      }
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
      if (profile.interests.isNotEmpty) {
        _selectedInterests = List<String>.from(profile.interests);
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
              city: u.city,
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
        final fieldBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.backgroundGrey.withValues(alpha: 0.7),
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
                          color: AppColors.ownerHomePrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppResources.spacingM,
              AppResources.spacingS,
              AppResources.spacingM,
              AppResources.spacingL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.settingsIconTileBackground,
                    backgroundImage:
                        displayAvatarUrl != null && displayAvatarUrl.isNotEmpty
                        ? NetworkImage(displayAvatarUrl)
                        : null,
                    child: displayAvatarUrl == null || displayAvatarUrl.isEmpty
                        ? Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ownerHomePrimary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppResources.spacingS),
                Center(
                  child: FilledButton(
                    onPressed: saving ? null : () => _pickAndUploadPhoto(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.settingsIconTileBackground,
                      foregroundColor: AppColors.ownerHomePrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Change Photo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                _LabeledField(
                  label: 'Full Name',
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldBorder.copyWith(
                        borderSide: const BorderSide(color: AppColors.ownerHomePrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldBorder,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Phone Number',
                  child: IntlPhoneField(
                    key: ValueKey<String>(_initialPhoneNumber),
                    disableLengthCheck: true,
                    initialValue: _stripCountryCode(_initialPhoneNumber),
                    initialCountryCode: 'US',
                    decoration: InputDecoration(
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldBorder.copyWith(
                        borderSide: const BorderSide(color: AppColors.ownerHomePrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: const Icon(
                            Icons.verified,
                            color: AppColors.ownerHomePrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingM),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _bioController,
                  builder: (_, value, __) {
                    return _LabeledField(
                      label: 'Bio',
                      trailing: Text(
                        '${value.text.length}/160',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      child: TextField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 160,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder.copyWith(
                            borderSide: const BorderSide(color: AppColors.ownerHomePrimary),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppResources.spacingM),
                _LabeledField(
                  label: 'Interests',
                  trailing: TextButton(
                    onPressed: _openInterestsEditor,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ownerHomePrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Edit Interests',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  child: Wrap(
                    spacing: AppResources.spacingS,
                    runSpacing: AppResources.spacingS,
                    children: _selectedInterests.isEmpty
                        ? [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.backgroundGrey.withValues(alpha: 0.7),
                                ),
                              ),
                              child: const Text(
                                'No interests selected yet. Tap "Edit Interests" to choose what you like.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ]
                        : _selectedInterests
                            .map(
                              (interest) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.settingsIconTileBackground,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: AppColors.ownerHomePrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
  final Widget? trailing;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppResources.spacingXS),
        child,
      ],
    );
  }
}

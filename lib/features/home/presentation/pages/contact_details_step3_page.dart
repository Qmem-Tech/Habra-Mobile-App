import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/validation/business_onboarding_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/business_registration_hours_sheet.dart';
import 'add_photos_step4_page.dart';

/// Contact Details step 3: Phone, Email, Website (optional), Business hours, Next.
class ContactDetailsStep3Page extends StatefulWidget {
  const ContactDetailsStep3Page({super.key, this.step2Data = const {}});

  final Map<String, String> step2Data;

  @override
  State<ContactDetailsStep3Page> createState() =>
      _ContactDetailsStep3PageState();
}

class _ContactDetailsStep3PageState extends State<ContactDetailsStep3Page> {
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  late RegistrationHoursResult _hoursResult;

  @override
  void initState() {
    super.initState();
    _hoursResult = RegistrationHoursResult.defaultSchedule();
  }

  Future<void> _onEditHours() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    final updated = await showBusinessRegistrationHoursSheet(
      context,
      initial: _hoursResult,
    );
    if (!mounted || updated == null) return;
    setState(() => _hoursResult = updated);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isActive = i <= 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandPrimary : AppColors.progressInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Contact Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Next you\'ll add photos, then Business License (required) and EIN Proof (optional).',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLabel('Business Phone'),
                const SizedBox(height: 8),
                IntlPhoneField(
                  disableLengthCheck: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  initialCountryCode: 'US',
                  onChanged: (phone) => setState(() => _phoneNumber = phone.completeNumber),
                  validator: (PhoneNumber? phone) {
                    if (phone == null || phone.number.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return BusinessOnboardingValidators.businessPhone(
                      phone.completeNumber,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Business Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: BusinessOnboardingValidators.businessEmail,
                ),
                const SizedBox(height: 16),
                _buildLabel('Website (Optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: BorderSide(color: AppColors.backgroundGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: BusinessOnboardingValidators.businessWebsiteOptional,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Business',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _onEditHours,
                      icon: Icon(Icons.edit, size: 18, color: AppColors.brandSecondary),
                      label: Text(
                        'Edit Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(7, (i) {
                  final isClosed = _hoursResult.dayClosed[i];
                  final hoursText = _hoursResult.hoursLabelForDay(i);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          RegistrationHoursResult.weekdayNames[i],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: isClosed
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                )
                              : null,
                          decoration: isClosed
                              ? BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: Text(
                            hoursText,
                            style: TextStyle(
                              fontSize: 14,
                              color: isClosed
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Next',
            onPressed: _isLoading ? null : _onNext,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Future<void> _onNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final hoursErr = BusinessOnboardingValidators.registrationBusinessHours(
      dayClosed: _hoursResult.dayClosed,
      openingTime: _hoursResult.openingTime,
      closingTime: _hoursResult.closingTime,
    );
    if (hoursErr != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hoursErr)),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    final step3Data = {
      ...widget.step2Data,
      'phone': _phoneNumber,
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'opening_time': _hoursResult.openingTime,
      'closing_time': _hoursResult.closingTime,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPhotosStep4Page(step3Data: step3Data),
      ),
    );
  }
}

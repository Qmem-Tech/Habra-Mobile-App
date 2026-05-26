import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../home/presentation/widgets/business_registration_hours_sheet.dart';
import 'business_photos_page.dart';

class BusinessContactPage extends StatefulWidget {
  const BusinessContactPage({super.key});

  @override
  State<BusinessContactPage> createState() => _BusinessContactPageState();
}

class _BusinessContactPageState extends State<BusinessContactPage> {
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  late RegistrationHoursResult _hoursResult;

  @override
  void initState() {
    super.initState();
    _hoursResult = RegistrationHoursResult.defaultSchedule();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _onEditHours() async {
    final updated = await showBusinessRegistrationHoursSheet(
      context,
      initial: _hoursResult,
    );
    if (!mounted || updated == null) return;
    setState(() => _hoursResult = updated);
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final hoursMap = {
        for (var i = 0; i < 7; i++)
          RegistrationHoursResult.weekdayNames[i]: _hoursResult.dayClosed[i]
              ? 'Closed'
              : _hoursResult.openDaysHoursLabel,
      };
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BusinessPhotosPage(),
          settings: RouteSettings(
            arguments: {
              'phone': _phoneNumber,
              'email': _emailController.text,
              'website': _websiteController.text,
              'hours': hoursMap,
              'opening_time': _hoursResult.openingTime,
              'closing_time': _hoursResult.closingTime,
            },
          ),
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
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: AppResources.spacingL),
            child: Row(
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index < 3 ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < 3 ? AppColors.brandPrimary : AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppResources.spacingXL),

                // Title
                Text(
                  'Contact Details',
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingXXL),

                // Business Phone field
                Text(
                  'Business Phone',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                IntlPhoneField(
                  decoration: InputDecoration(
                    hintText: 'Enter business phone number',
                    hintStyle: AppFonts.body(color: AppColors.textTertiary),
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
                  ),
                  initialCountryCode: 'US',
                  onChanged: (phone) => setState(() => _phoneNumber = phone.completeNumber),
                  validator: (value) {
                    if (value == null || value.number.isEmpty) {
                      return 'Please enter business phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppResources.spacingL),

                // Business Email field
                Text(
                  'Business Email',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter business email',
                    hintStyle: AppFonts.body(color: AppColors.textTertiary),
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter business email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppResources.spacingL),

                // Website field (Optional)
                Text(
                  'Website (Optional)',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'Enter website URL',
                    hintStyle: AppFonts.body(color: AppColors.textTertiary),
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
                  ),
                ),
                const SizedBox(height: AppResources.spacingXL),

                // Divider
                Divider(color: AppColors.backgroundGrey),
                const SizedBox(height: AppResources.spacingL),

                // Business Hours section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Business',
                      style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                    ),
                    TextButton.icon(
                      onPressed: _onEditHours,
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppColors.brandPrimary,
                      ),
                      label: Text(
                        'Edit Hours',
                        style: AppFonts.bodySmall(color: AppColors.brandPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppResources.spacingM),

                // Business hours list
                ...List.generate(7, (i) {
                  final isClosed = _hoursResult.dayClosed[i];
                  final label =
                      isClosed ? 'Closed' : _hoursResult.openDaysHoursLabel;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: AppResources.spacingM),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.backgroundGrey.withValues(alpha:0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            RegistrationHoursResult.weekdayNames[i],
                            style: AppFonts.body(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppResources.spacingS),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppResources.spacingM,
                              vertical: AppResources.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? AppColors.error.withValues(alpha:0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppResources.radiusS),
                            ),
                            child: Text(
                              label,
                              style: AppFonts.bodySmall(
                                color: isClosed ? AppColors.error : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppResources.spacingXXL),

                // Next button
                SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

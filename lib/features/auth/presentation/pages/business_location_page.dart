import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'business_contact_page.dart';

class BusinessLocationPage extends StatefulWidget {
  const BusinessLocationPage({super.key});

  @override
  State<BusinessLocationPage> createState() => _BusinessLocationPageState();
}

class _BusinessLocationPageState extends State<BusinessLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _streetAddressController = TextEditingController();
  final _suiteUnitController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  @override
  void dispose() {
    _streetAddressController.dispose();
    _suiteUnitController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _onUseCurrentLocation() {
    // TODO: Implement location services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location services coming soon')),
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BusinessContactPage(),
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
                  width: index < 2 ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < 2 ? AppColors.brandPrimary : AppColors.backgroundGrey,
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
                  'Where is your business located?',
                  style: AppFonts.largeTitle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingL),

                // Use Current Location button
                SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: OutlinedButton.icon(
                    onPressed: _onUseCurrentLocation,
                    icon: Icon(
                      Icons.explore,
                      color: AppColors.brandPrimary,
                    ),
                    label: Text(
                      'Use Current Location',
                      style: AppFonts.button(color: AppColors.brandPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimaryLight.withValues(alpha:0.1),
                      foregroundColor: AppColors.brandPrimary,
                      side: BorderSide(color: AppColors.brandPrimaryLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingXL),

                // Street Address field
                Text(
                  'Street Address',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _streetAddressController,
                  decoration: InputDecoration(
                    hintText: 'Enter street address',
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
                      return 'Please enter street address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppResources.spacingL),

                // Suite / Unit field
                Text(
                  'Suite / Unit',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _suiteUnitController,
                  decoration: InputDecoration(
                    hintText: 'Enter suite or unit (optional)',
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
                const SizedBox(height: AppResources.spacingL),

                // City field
                Text(
                  'City',
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Enter city',
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
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppResources.spacingL),

                // State and ZIP Code row
                Row(
                  children: [
                    // State field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'State',
                            style: AppFonts.body(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              hintText: 'State',
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
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppResources.spacingM),
                    // ZIP Code field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ZIP Code',
                            style: AppFonts.body(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          TextFormField(
                            controller: _zipCodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'ZIP Code',
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
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: AppFonts.button(color: AppColors.textOnPrimary),
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

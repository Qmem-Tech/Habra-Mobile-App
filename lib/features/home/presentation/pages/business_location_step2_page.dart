import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/validation/business_onboarding_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/business_address_input.dart';
import 'contact_details_step3_page.dart';

/// Business location step 2: Use Current Location, Street, Suite, City, State, ZIP, Next.
class BusinessLocationStep2Page extends StatefulWidget {
  const BusinessLocationStep2Page({
    super.key,
    this.step1Data = const {},
  });

  final Map<String, String> step1Data;

  @override
  State<BusinessLocationStep2Page> createState() =>
      _BusinessLocationStep2PageState();
}

class _BusinessLocationStep2PageState extends State<BusinessLocationStep2Page> {
  final _streetController = TextEditingController();
  final _suiteController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'AL');
  final _zipController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _streetController.dispose();
    _suiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
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
            final isActive = i <= 1;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Where is your business located?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              BusinessAddressInput(
                streetController: _streetController,
                suiteController: _suiteController,
                cityController: _cityController,
                stateController: _stateController,
                zipController: _zipController,
                defaultState: 'AL',
                showOptionalAddressMethods: false,
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
            text: 'Next',
            onPressed: _isLoading ? null : _onNext,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    final err = BusinessOnboardingValidators.locationFields(
      street: _streetController.text,
      city: _cityController.text,
      state: _stateController.text,
      zip: _zipController.text,
    );
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    final step2Data = {
      ...widget.step1Data,
      'address_street': _streetController.text.trim(),
      'address_suite': _suiteController.text.trim(),
      'address_city': _cityController.text.trim(),
      'address_state': _stateController.text.trim(),
      'address_zip': _zipController.text.trim(),
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactDetailsStep3Page(step2Data: step2Data),
      ),
    );
  }
}

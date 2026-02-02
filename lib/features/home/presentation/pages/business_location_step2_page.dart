import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import 'contact_details_step3_page.dart';

/// Business location step 2: Use Current Location, Street, Suite, City, State, ZIP, Next.
class BusinessLocationStep2Page extends StatefulWidget {
  const BusinessLocationStep2Page({super.key});

  @override
  State<BusinessLocationStep2Page> createState() =>
      _BusinessLocationStep2PageState();
}

class _BusinessLocationStep2PageState extends State<BusinessLocationStep2Page> {
  final _streetController = TextEditingController();
  final _suiteController = TextEditingController();
  final _cityController = TextEditingController(text: 'Restaurant & Cafe');
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
              _buildUseCurrentLocationButton(),
              const SizedBox(height: 24),
              _buildLabel('Street Address'),
              const SizedBox(height: 8),
              _buildTextField(_streetController, 'Enter street address'),
              const SizedBox(height: 16),
              _buildLabel('Suite / Unit'),
              const SizedBox(height: 8),
              _buildTextField(_suiteController, 'Optional'),
              const SizedBox(height: 16),
              _buildLabel('City'),
              const SizedBox(height: 8),
              _buildTextField(_cityController, 'Select city', isDropdown: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('State'),
                        const SizedBox(height: 8),
                        _buildTextField(_stateController, 'AL'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('ZIP Code'),
                        const SizedBox(height: 8),
                        _buildTextField(_zipController, 'ZIP'),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildUseCurrentLocationButton() {
    return Material(
      color: AppColors.brandPrimary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppResources.radiusM),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.my_location, color: AppColors.brandPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Use Current Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
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

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isDropdown = false}) {
    return TextField(
      controller: controller,
      readOnly: isDropdown,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        suffixIcon: isDropdown ? const Icon(Icons.arrow_drop_down) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          borderSide: BorderSide(color: AppColors.backgroundGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          borderSide: BorderSide(color: AppColors.backgroundGrey),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _onNext() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactDetailsStep3Page(),
      ),
    );
  }
}

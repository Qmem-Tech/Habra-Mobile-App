import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/business_brand_entity.dart';

/// Add a new location to an existing business brand (Add New Presence → New Location flow).
/// Step 2 of 2: address fields, same hours toggle, Complete Registration.
class AddLocationPage extends StatefulWidget {
  final BusinessBrandEntity selectedBrand;

  const AddLocationPage({super.key, required this.selectedBrand});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _streetController = TextEditingController();
  final _suiteController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'AL');
  final _zipController = TextEditingController();
  bool _sameHoursAsMain = true;
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
          children: [
            _stepDot(active: true),
            const SizedBox(width: 6),
            _stepDot(active: true),
          ],
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
                'Add Location',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildBrandAssetsBanner(),
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
              const SizedBox(height: 24),
              _buildSameHoursSection(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Complete Registration',
            onPressed: _isLoading ? null : _onComplete,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _stepDot({required bool active}) {
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : AppColors.progressInactive,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBrandAssetsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.brandPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand Assets Inherited',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This location will automatically use the logo and business category from the parent business profile.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location, color: AppColors.brandSecondary, size: 24),
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

  Widget _buildSameHoursSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Same hours as main?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use parent business hours.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _sameHoursAsMain,
            onChanged: (v) => setState(() => _sameHoursAsMain = v),
            activeTrackColor: AppColors.brandPrimary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }

  Future<void> _onComplete() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Pop back to Business Locations / Home (AddLocation → ChooseBrand → AddNewPresence)
    for (int i = 0; i < 3 && context.mounted; i++) {
      Navigator.pop(context);
    }
  }
}

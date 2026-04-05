import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';
import '../services/location_service.dart';
import '../domain/business_address_data.dart';
import '../permissions/app_permission.dart';
import '../services/permission_service.dart';
import 'error_display_helper.dart';
import 'street_address_field.dart';
import '../../injection/injection_container.dart' as di;

/// Reusable business address input.
///
/// When [showOptionalAddressMethods] is true (default): field hints and coordinate helper text.
/// The address row always includes **Use current location** and typed suggestions on the street field.
class BusinessAddressInput extends StatelessWidget {
  const BusinessAddressInput({
    super.key,
    required this.streetController,
    required this.suiteController,
    required this.cityController,
    required this.stateController,
    required this.zipController,
    this.defaultState = 'AL',
    /// When false, tighter field hints (e.g. new business registration).
    this.showOptionalAddressMethods = true,
    /// When non-null, uses [TextFormField] so [FormState.validate] runs (e.g. registration).
    this.streetValidator,
    this.cityValidator,
    this.stateValidator,
    this.zipValidator,
    /// Called after street/city/state/ZIP are filled from a suggestion or current location.
    this.onAddressApplied,
  });

  final TextEditingController streetController;
  final TextEditingController suiteController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipController;
  final String defaultState;
  final bool showOptionalAddressMethods;
  final String? Function(String?)? streetValidator;
  final String? Function(String?)? cityValidator;
  final String? Function(String?)? stateValidator;
  final String? Function(String?)? zipValidator;
  final ValueChanged<BusinessAddressData>? onAddressApplied;

  void _applyAddress(BuildContext context, BusinessAddressData data) {
    if (data.street != null) streetController.text = data.street!;
    if (data.city != null) cityController.text = data.city!;
    if (data.state != null) stateController.text = data.state!;
    if (data.zipCode != null) zipController.text = data.zipCode!;
    if (data.suite != null) suiteController.text = data.suite!;
    onAddressApplied?.call(data);
  }

  @override
  Widget build(BuildContext context) {
    final showFieldHints = showOptionalAddressMethods;
    final streetHint = showFieldHints
        ? 'Street, city, state — suggestions appear as you type'
        : '';
    final suiteHint = showFieldHints ? 'Optional' : '';
    final stateHint = showFieldHints ? defaultState : '';
    final zipHint = showFieldHints ? 'ZIP' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCurrentLocationOnly(context),
        const SizedBox(height: 20),
        _buildLabel('Street Address'),
        const SizedBox(height: 8),
        StreetAddressField(
          controller: streetController,
          hintText: streetHint,
          decoration: _outlineFieldDecoration(),
          validator: streetValidator,
          onAddressPicked: (data) => _applyAddress(context, data),
        ),
        if (showOptionalAddressMethods) ...[
          const SizedBox(height: 6),
          Text(
            'Pick a suggestion below to fill the form and save map coordinates when available.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildLabel('Suite / Unit'),
        const SizedBox(height: 8),
        _buildTextField(context, suiteController, suiteHint),
        const SizedBox(height: 16),
        _buildLabel('City'),
        const SizedBox(height: 8),
        _buildTextField(
          context,
          cityController,
          '',
          validator: cityValidator,
        ),
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
                  _buildTextField(
                    context,
                    stateController,
                    stateHint,
                    validator: stateValidator,
                    textCapitalization: stateValidator != null
                        ? TextCapitalization.characters
                        : TextCapitalization.none,
                    inputFormatters: stateValidator != null
                        ? <TextInputFormatter>[_StateAbbrevInputFormatter()]
                        : null,
                  ),
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
                  _buildTextField(
                    context,
                    zipController,
                    zipHint,
                    validator: zipValidator,
                    inputFormatters: zipValidator != null
                        ? <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                            LengthLimitingTextInputFormatter(10),
                          ]
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentLocationOnly(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Use your current address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We\'ll fill street, city, state, and ZIP. You can edit the fields below.',
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: AppResources.buttonHeightL,
          child: OutlinedButton.icon(
            onPressed: () => _onUseCurrentLocation(context),
            icon: Icon(
              Icons.my_location_rounded,
              size: 22,
              color: AppColors.brandPrimary,
            ),
            label: const Text(
              'Use current location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
              side: BorderSide(
                color: AppColors.brandPrimary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
              alignment: Alignment.center,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onUseCurrentLocation(BuildContext context) async {
    final granted = await di.sl<PermissionService>().requestWithDialog(
      context,
      AppPermission.location,
    );
    if (!granted || !context.mounted) return;
    final result = await di.sl<LocationService>().getCurrentLocationAsAddress();
    if (!context.mounted) return;
    result.fold(
      (f) => ErrorDisplayHelper.show(context, message: f.message, title: 'Location'),
      (data) {
        _applyAddress(context, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address set from current location')),
        );
      },
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

  InputDecoration _outlineFieldDecoration() {
    return InputDecoration(
      hintStyle: TextStyle(color: AppColors.textTertiary),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final decoration = _outlineFieldDecoration().copyWith(
      hintText: hint.isEmpty ? null : hint,
    );

    if (validator != null) {
      return TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        decoration: decoration,
      );
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: decoration,
    );
  }
}

/// Uppercase A-Z only, max 2 characters (US state abbreviation).
class _StateAbbrevInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (t.length > 2) {
      t = t.substring(0, 2);
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}


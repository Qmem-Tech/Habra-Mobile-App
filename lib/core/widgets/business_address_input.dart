import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../resources/app_resources.dart';
import '../services/location_service.dart';
import '../domain/business_address_data.dart';
import '../permissions/app_permission.dart';
import '../services/permission_service.dart';
import 'error_display_helper.dart';
import 'address_autocomplete_dialog.dart';
import 'address_map_picker_page.dart';
import '../../injection/injection_container.dart' as di;

/// Reusable business address input with 4 methods: current location, search, map picker, paste link.
class BusinessAddressInput extends StatelessWidget {
  const BusinessAddressInput({
    super.key,
    required this.streetController,
    required this.suiteController,
    required this.cityController,
    required this.stateController,
    required this.zipController,
    this.defaultState = 'AL',
    /// When false, only "Current location" is shown (new business registration flow).
    this.showOptionalAddressMethods = true,
  });

  final TextEditingController streetController;
  final TextEditingController suiteController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipController;
  final String defaultState;
  final bool showOptionalAddressMethods;

  void _applyAddress(BuildContext context, BusinessAddressData data) {
    if (data.street != null) streetController.text = data.street!;
    if (data.city != null) cityController.text = data.city!;
    if (data.state != null) stateController.text = data.state!;
    if (data.zipCode != null) zipController.text = data.zipCode!;
    if (data.suite != null) suiteController.text = data.suite!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showOptionalAddressMethods)
          _buildMethodButtons(context)
        else
          _buildCurrentLocationOnly(context),
        const SizedBox(height: 20),
        _buildLabel('Street Address'),
        const SizedBox(height: 8),
        _buildTextField(context, streetController, 'Enter street address'),
        const SizedBox(height: 16),
        _buildLabel('Suite / Unit'),
        const SizedBox(height: 8),
        _buildTextField(context, suiteController, 'Optional'),
        const SizedBox(height: 16),
        _buildLabel('City'),
        const SizedBox(height: 8),
        _buildTextField(context, cityController, 'Enter city'),
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
                  _buildTextField(context, stateController, defaultState),
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
                  _buildTextField(context, zipController, 'ZIP'),
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
          'Set address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _MethodChip(
          icon: Icons.my_location,
          label: 'Current location',
          onTap: () => _onUseCurrentLocation(context),
        ),
      ],
    );
  }

  Widget _buildMethodButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set address by',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MethodChip(
              icon: Icons.my_location,
              label: 'Current location',
              onTap: () => _onUseCurrentLocation(context),
            ),
            _MethodChip(
              icon: Icons.search,
              label: 'Search address',
              onTap: () => _onSearchAddress(context),
            ),
            _MethodChip(
              icon: Icons.map,
              label: 'Pick on map',
              onTap: () => _onPickOnMap(context),
            ),
            _MethodChip(
              icon: Icons.link,
              label: 'Paste link',
              onTap: () => _onPasteLink(context),
            ),
          ],
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

  Future<void> _onSearchAddress(BuildContext context) async {
    final initial = streetController.text.isNotEmpty
        ? '${streetController.text}, ${cityController.text}'.trim()
        : '';
    final data = await showDialog<BusinessAddressData>(
      context: context,
      builder: (_) => AddressAutocompleteDialog(initialQuery: initial),
    );
    if (!context.mounted) return;
    final ctx = context;
    if (data != null) {
      _applyAddress(ctx, data);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Address found')),
      );
    }
  }

  Future<void> _onPickOnMap(BuildContext context) async {
    double? initLat;
    double? initLng;
    if (streetController.text.isNotEmpty || cityController.text.isNotEmpty) {
      final q = '${streetController.text}, ${cityController.text}'.trim();
      if (q.isNotEmpty) {
        final r = await di.sl<LocationService>().geocodeAddress(q);
        r.fold((_) {}, (c) {
          initLat = c.lat;
          initLng = c.lng;
        });
      }
    }
    if (!context.mounted) return;
    final data = await Navigator.push<BusinessAddressData>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressMapPickerPage(
          initialLat: initLat,
          initialLng: initLng,
        ),
      ),
    );
    if (!context.mounted) return;
    final ctx = context;
    if (data != null) {
      _applyAddress(ctx, data);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Address set from map')),
      );
    }
  }

  Future<void> _onPasteLink(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final ctx = context;
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty. Copy a Google Maps link first.')),
      );
      return;
    }
    final result = di.sl<LocationService>().parseGoogleMapsLink(text);
    result.fold(
      (f) => ErrorDisplayHelper.show(ctx, message: f.message, title: 'Invalid link'),
      (coords) async {
        final revResult = await di.sl<LocationService>()
            .reverseGeocodeToAddress(coords.lat, coords.lng);
        if (!ctx.mounted) return;
        revResult.fold(
          (f) => ErrorDisplayHelper.show(ctx, message: f.message, title: 'Address'),
          (addr) {
            _applyAddress(ctx, addr);
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Address set from link')),
            );
          },
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

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
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
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandPrimary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppResources.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.brandPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
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
}


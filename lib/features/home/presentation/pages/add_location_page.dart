import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/domain/business_address_data.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/business_address_input.dart';
import '../../domain/entities/business_brand_entity.dart';
import '../../domain/entities/business_presence.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../../core/widgets/error_display_helper.dart';
import 'listing_status_page.dart';

/// Add a new location to an existing business brand (Add New Presence → New Location flow).
/// Step 2 of 2: address fields, same hours toggle, Complete Registration.
class AddLocationPage extends StatefulWidget {
  const AddLocationPage({
    super.key,
    required this.selectedBrand,
    this.parentPresence,
  });

  final BusinessBrandEntity selectedBrand;
  final BusinessPresence? parentPresence;

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _streetController = TextEditingController();
  final _suiteController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'AL');
  final _zipController = TextEditingController();
  final _locationLabelController = TextEditingController();
  bool _sameHoursAsMain = true;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  void _onAddressApplied(BusinessAddressData data) {
    setState(() {
      if (data.hasCoordinates) {
        _latitude = data.latitude;
        _longitude = data.longitude;
      }
    });
  }

  @override
  void dispose() {
    _streetController.dispose();
    _suiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _locationLabelController.dispose();
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
              BusinessAddressInput(
                streetController: _streetController,
                suiteController: _suiteController,
                cityController: _cityController,
                stateController: _stateController,
                zipController: _zipController,
                defaultState: 'AL',
                onAddressApplied: _onAddressApplied,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _locationLabelController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Location label (optional)',
                  hintText: 'e.g. Downtown, Airport',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Map coordinates will be saved for this listing.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    final ctx = context;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      final street = _streetController.text.trim();
      final suite = _suiteController.text.trim();
      final addressStreet = suite.isNotEmpty ? '$street, $suite' : street;

      final parent = widget.parentPresence;
      final cityTrim = _cityController.text.trim();
      final labelTrim = _locationLabelController.text.trim();
      final locationLabel =
          labelTrim.isNotEmpty ? labelTrim : (cityTrim.isNotEmpty ? cityTrim : null);
      final data = <String, dynamic>{
        'name': '${widget.selectedBrand.name} - ${cityTrim.isNotEmpty ? cityTrim : 'Location'}',
        'description': parent?.category,
        'address_street': addressStreet.isNotEmpty ? addressStreet : null,
        'address_city': cityTrim.isNotEmpty ? cityTrim : 'Unknown',
        'address_state':
            _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        'address_zip': _zipController.text.trim().isNotEmpty ? _zipController.text.trim() : null,
        'logo_url': parent?.logoUrl ?? widget.selectedBrand.logoUrl,
        'background_url': parent?.backgroundUrl,
        if (parent != null)
          'parent_business_id': parent.parentBusinessId ?? parent.id,
        if (locationLabel != null) 'location_label': locationLabel,
        if (_latitude != null && _longitude != null) 'latitude': _latitude,
        if (_latitude != null && _longitude != null) 'longitude': _longitude,
      };
      // Additional locations inherit parent approval; only brand-new businesses
      // use default pending in [DashboardSupabaseDataSource.createBusiness].
      if (parent != null) {
        if (parent.isPendingApproval) {
          data['approval_status'] = 'pending';
          data['is_verified'] = false;
        } else if (parent.statusText == 'rejected') {
          data['approval_status'] = 'rejected';
          data['is_verified'] = false;
        } else {
          data['approval_status'] = 'approved';
          data['is_verified'] = parent.isVerified;
        }
      }
      if (_sameHoursAsMain && parent != null) {
        final hours = await di.sl<DashboardCubit>().getBusinessHours(parent.id);
        if (hours != null) {
          data['opening_time'] = hours['opening_time'];
          data['closing_time'] = hours['closing_time'];
        }
      } else {
        data['opening_time'] = '09:00';
        data['closing_time'] = '17:00';
      }
      data.removeWhere((_, v) => v == null);

      final businessId =
          await di.sl<DashboardCubit>().createBusiness(userId, data);
      if (!ctx.mounted) return;
      if (businessId == null) {
        throw Exception('Failed to create location');
      }
      if (parent != null) {
        try {
          final repo = di.sl<DashboardRepository>();
          final categoryIds = await repo.listCategoryIdsForBusiness(parent.id);
          if (categoryIds.isNotEmpty) {
            await repo.replaceBusinessCategoryLinks(businessId, categoryIds);
          }
        } catch (_) {
          // Listing exists; category copy is best-effort.
        }
      }
      if (!ctx.mounted) return;
      setState(() => _isLoading = false);
      if (!ctx.mounted) return;
      final showAsLive = parent != null &&
          !parent.isPendingApproval &&
          parent.statusText != 'rejected';
      final cityForStatus = cityTrim.isNotEmpty &&
              cityTrim.toLowerCase() != 'unknown'
          ? cityTrim
          : null;
      final streetTrim = _streetController.text.trim();
      final locationLine = cityForStatus == null
          ? null
          : (streetTrim.isNotEmpty ? '$streetTrim, $cityTrim' : cityTrim);

      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ListingStatusPage(
            isVerified: showAsLive,
            businessId: businessId,
            businessName: widget.selectedBrand.name,
            cityName: cityForStatus,
            imageUrl: parent?.logoUrl ?? widget.selectedBrand.logoUrl ?? '',
            locationText: locationLine,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (ctx.mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayHelper.show(ctx, error: e, title: 'Could not add location');
      }
    }
  }
}

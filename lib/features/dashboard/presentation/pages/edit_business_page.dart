import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/subscription/business_subscription_policy.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/widgets/business_address_input.dart';
import '../../../../core/domain/business_address_data.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/business_presence.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/business_gallery_photos_dialog.dart';

class EditBusinessPage extends StatefulWidget {
  const EditBusinessPage({super.key, required this.business});

  final BusinessPresence business;

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  int get _maxGallery => BusinessSubscriptionPolicy.maxGalleryImages(
      widget.business.subscriptionTier);

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _streetController;
  late final TextEditingController _suiteController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _locationLabelController;

  File? _logoFile;
  File? _backgroundFile;
  late List<String> _galleryUrls;
  bool _showValidation = false;
  double? _latitude;
  double? _longitude;
  String? _placeId;
  String? _googleMapsUrl;

  static final RegExp _emailRe = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(text: widget.business.category);
    _phoneController = TextEditingController(text: widget.business.phone ?? '');
    _emailController = TextEditingController(text: widget.business.email ?? '');
    _websiteController = TextEditingController(text: widget.business.website ?? '');
    _streetController = TextEditingController(text: widget.business.locationName ?? '');
    _suiteController = TextEditingController();
    _cityController = TextEditingController(text: widget.business.city ?? '');
    _stateController = TextEditingController(text: widget.business.state ?? '');
    _zipController = TextEditingController();
    _locationLabelController = TextEditingController(
      text: widget.business.locationLabel ?? '',
    );
    _galleryUrls = List<String>.from(
      widget.business.imageUrls.where((u) => u.trim().isNotEmpty),
    );
    _latitude = widget.business.latitude;
    _longitude = widget.business.longitude;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncGalleryUrlsFromServer());
  }

  /// Home/cached [BusinessPresence] can omit or stale `image_urls`; refresh for this row.
  Future<void> _syncGalleryUrlsFromServer() async {
    try {
      final res = await Supabase.instance.client
          .from(SupabaseTables.businesses)
          .select('image_urls')
          .eq('id', widget.business.id)
          .maybeSingle();
      if (!mounted || res == null) return;
      final fresh = parseStringList(res['image_urls']);
      setState(() => _galleryUrls = fresh);
    } catch (_) {
      // Keep list from [widget.business] if the request fails.
    }
  }

  void _onBusinessAddressApplied(BusinessAddressData data) {
    setState(() {
      if (data.hasCoordinates) {
        _latitude = data.latitude;
        _longitude = data.longitude;
      }
      _placeId = data.placeId;
      _googleMapsUrl = data.googleMapsUrl;
    });
  }

  Future<void> _openGalleryPhotos() async {
    final ctx = context;
    final updated = await showDialog<List<String>?>(
      context: ctx,
      builder: (_) => BlocProvider.value(
        value: ctx.read<DashboardCubit>(),
        child: BusinessGalleryPhotosDialog(
          businessId: widget.business.id,
          businessName: widget.business.displayName,
          initialImageUrls: _galleryUrls,
          subscriptionTier: widget.business.subscriptionTier,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _galleryUrls = List<String>.from(updated));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _suiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) setState(() => _logoFile = file);
  }

  Future<void> _pickBackground() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) setState(() => _backgroundFile = file);
  }

  String? _validate() {
    if (_nameController.text.trim().isEmpty) return 'Business name is required';
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    final website = _websiteController.text.trim();
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Please enter a valid website URL (https://...)';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final ctx = context;
    for (final f in [_logoFile, _backgroundFile]) {
      if (f != null) {
        final size = await f.length();
        if (!ctx.mounted) return;
        if (size > FileUtils.maxImageBytes) {
          ErrorDisplayHelper.show(
            ctx,
            message: 'Image is ${FileUtils.formatFileSize(size)}. Max 5 MB per file.',
            title: 'File too large',
          );
          return;
        }
      }
    }
    if (!ctx.mounted) return;

    final cubit = ctx.read<DashboardCubit>();
    LoaderHelper.show(ctx, message: 'Saving...');

    try {
      final street = _streetController.text.trim();
      final suite = _suiteController.text.trim();
      final addressStreet = suite.isNotEmpty ? '$street${street.isNotEmpty ? ', ' : ''}$suite' : street;
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'website': _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        'address_street': addressStreet.isNotEmpty ? addressStreet : null,
        'address_city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        'address_state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        'address_zip': _zipController.text.trim().isNotEmpty ? _zipController.text.trim() : null,
        if (_latitude != null && _longitude != null) 'latitude': _latitude,
        if (_latitude != null && _longitude != null) 'longitude': _longitude,
        if (_placeId != null) 'place_id': _placeId,
        if (_googleMapsUrl != null) 'google_maps_url': _googleMapsUrl,
        if (widget.business.parentBusinessId != null)
          'location_label': () {
            final t = _locationLabelController.text.trim();
            return t.isNotEmpty ? t : null;
          }(),
      };

      if (_logoFile != null) {
        data['logo_url'] = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.business.id}/logo',
          _logoFile!,
        );
      }
      if (_backgroundFile != null) {
        data['background_url'] = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.business.id}/background',
          _backgroundFile!,
        );
      }

      data.removeWhere((_, v) => v == null);
      final success = await cubit.updateBusiness(widget.business.id, data);
      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (success) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Business updated')),
        );
        Navigator.pop(ctx, true);
      } else {
        ErrorDisplayHelper.show(ctx, message: 'We couldn\'t update your business. Please try again.', title: 'Update failed');
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Upload failed');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Edit Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Images'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildImageUpload(
                  label: 'Logo',
                  file: _logoFile,
                  url: widget.business.logoUrl,
                  onTap: _pickLogo,
                ),
                const SizedBox(width: 16),
                _buildImageUpload(
                  label: 'Background',
                  file: _backgroundFile,
                  url: widget.business.backgroundUrl,
                  onTap: _pickBackground,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'More photos',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_galleryUrls.length} of $_maxGallery slots used on your current plan. '
              'These appear alongside your listing in Explore.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (_galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = _galleryUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      child: Image.network(
                        url,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: AppColors.backgroundGrey,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textTertiary,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openGalleryPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: const Text('Add or remove photos'),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Basic Info'),
            const SizedBox(height: 12),
            _buildField(
              'Business Name *',
              _nameController,
              errorText: _showValidation && _nameController.text.trim().isEmpty
                  ? 'Business name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildField('Description', _descriptionController, maxLines: 3),
            const SizedBox(height: 24),
            _sectionTitle('Contact'),
            const SizedBox(height: 12),
            _buildField('Phone', _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField(
              'Email',
              _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _showValidation &&
                      _emailController.text.trim().isNotEmpty &&
                      !_emailRe.hasMatch(_emailController.text.trim())
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              'Website',
              _websiteController,
              keyboardType: TextInputType.url,
              errorText: () {
                if (!_showValidation) return null;
                final w = _websiteController.text.trim();
                if (w.isEmpty) return null;
                final uri = Uri.tryParse(w);
                if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
                  return 'Enter a valid URL (https://...)';
                }
                return null;
              }(),
            ),
            if (widget.business.parentBusinessId != null) ...[
              const SizedBox(height: 12),
              _buildField(
                'Location label',
                _locationLabelController,
                hintText: 'Short name for this branch (optional)',
              ),
            ],
            const SizedBox(height: 24),
            _sectionTitle('Address'),
            const SizedBox(height: 12),
            BusinessAddressInput(
              streetController: _streetController,
              suiteController: _suiteController,
              cityController: _cityController,
              stateController: _stateController,
              zipController: _zipController,
              defaultState: 'AL',
              onAddressApplied: _onBusinessAddressApplied,
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Map coordinates saved for this listing (nearby search and maps).',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            AppButton(text: 'Save Changes', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary));

  Widget _buildImageUpload({
    required String label,
    File? file,
    String? url,
    required VoidCallback onTap,
  }) {
    final hasImage = file != null || (url != null && url.isNotEmpty);
    final urlStr = url ?? '';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppResources.radiusM),
                border: Border.all(color: AppColors.backgroundGrey),
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppResources.radiusM),
                          child: file != null
                              ? Image.file(file, fit: BoxFit.cover)
                              : Image.network(
                                  urlStr,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                                ),
                        ),
                        if (file != null)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: FutureBuilder<int>(
                              future: file.length(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                final bytes = snapshot.requireData;
                                final overLimit = bytes > FileUtils.maxImageBytes;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${FileUtils.formatFileSize(bytes)} / 5 MB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: overLimit ? AppColors.error : Colors.white,
                                      fontWeight: overLimit ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    )
                  : const Center(child: Icon(Icons.add_photo_alternate, color: AppColors.textTertiary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? errorText,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (_showValidation) setState(() {});
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.backgroundGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.backgroundGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.brandPrimary),
            ),
            errorText: errorText,
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

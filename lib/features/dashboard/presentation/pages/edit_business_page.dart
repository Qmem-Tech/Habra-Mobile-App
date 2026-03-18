import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/business_presence.dart';
import '../bloc/dashboard_cubit.dart';

class EditBusinessPage extends StatefulWidget {
  const EditBusinessPage({super.key, required this.business});

  final BusinessPresence business;

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  File? _logoFile;
  File? _backgroundFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(text: widget.business.category);
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _streetController = TextEditingController(text: widget.business.locationName ?? '');
    _cityController = TextEditingController(text: widget.business.city ?? '');
    _stateController = TextEditingController(text: widget.business.state ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }
    final ctx = context;
    final cubit = ctx.read<DashboardCubit>();
    LoaderHelper.show(ctx, message: 'Saving...');

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'website': _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        'address_street': _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
        'address_city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        'address_state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
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
            const SizedBox(height: 24),
            _sectionTitle('Basic Info'),
            const SizedBox(height: 12),
            _buildField('Business Name', _nameController),
            const SizedBox(height: 12),
            _buildField('Description', _descriptionController, maxLines: 3),
            const SizedBox(height: 24),
            _sectionTitle('Contact'),
            const SizedBox(height: 12),
            _buildField('Phone', _phoneController),
            const SizedBox(height: 12),
            _buildField('Email', _emailController),
            const SizedBox(height: 12),
            _buildField('Website', _websiteController),
            const SizedBox(height: 24),
            _sectionTitle('Address'),
            const SizedBox(height: 12),
            _buildField('Street', _streetController),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('City', _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('State', _stateController)),
            ]),
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
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      child: file != null
                          ? Image.file(file, fit: BoxFit.cover)
                          : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                    )
                  : const Center(child: Icon(Icons.add_photo_alternate, color: AppColors.textTertiary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

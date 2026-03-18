import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart' show AppButton, AppOutlinedButton;
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/dashboard_cubit.dart';

enum OfferType { percentOff, fixedAmount, freeItem }

class CreateDealPage extends StatefulWidget {
  const CreateDealPage({super.key});

  @override
  State<CreateDealPage> createState() => _CreateDealPageState();
}

class _CreateDealPageState extends State<CreateDealPage> {
  OfferType _offerType = OfferType.percentOff;
  File? _imageFile;
  final _titleController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final Set<int> _selectedDays = {1, 2, 5, 6, 7};

  static const List<int> _dayKeys = [1, 2, 3, 4, 5, 6, 7];
  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _titleController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String? _getSelectedBusinessId() {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      return homeState.selectedPresence!.id;
    }
    return null;
  }

  Future<Map<String, dynamic>> _buildPayload(String status) async {
    String? imageUrl;
    if (_imageFile != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      imageUrl = await di.sl<StorageService>().uploadImage(
        SupabaseBuckets.deals,
        userId,
        _imageFile!,
      );
    }
    final now = DateTime.now();
    final validFrom = _startDateController.text.trim().isNotEmpty
        ? DateTime.tryParse(_startDateController.text.trim()) ?? now
        : now;
    final validUntil = _endDateController.text.trim().isNotEmpty
        ? DateTime.tryParse(_endDateController.text.trim()) ?? now.add(const Duration(days: 7))
        : now.add(const Duration(days: 7));
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'discount_percentage': int.tryParse(_discountController.text.trim()),
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'status': status,
      'image_url': imageUrl,
    };
  }

  Future<void> _publishDeal() async {
    final bizId = _getSelectedBusinessId();
    if (bizId == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the deal title and select a business')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Publishing...');
    try {
      final payload = await _buildPayload('active');
      if (!ctx.mounted) return;
      final result = await ctx.read<DashboardCubit>().createDeal(bizId, payload);
      if (!ctx.mounted) return;
      LoaderHelper.hide(ctx);
      if (result != null) {
        Navigator.pop(ctx, true);
      }
    } catch (e) {
      if (ctx.mounted) {
        LoaderHelper.hide(ctx);
        ErrorDisplayHelper.show(ctx, error: e, title: 'Could not create deal');
      }
    }
  }

  Future<void> _saveDraft() async {
    final bizId = _getSelectedBusinessId();
    if (bizId == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the deal title and select a business')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving draft...');
    try {
      final payload = await _buildPayload('draft');
      if (!ctx.mounted) return;
      final result = await ctx.read<DashboardCubit>().createDeal(bizId, payload);
      if (!ctx.mounted) return;
      LoaderHelper.hide(ctx);
      if (result != null) {
        Navigator.pop(ctx, true);
      }
    } catch (e) {
      if (ctx.mounted) {
        LoaderHelper.hide(ctx);
        ErrorDisplayHelper.show(ctx, error: e, title: 'Could not create deal');
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _imageFile = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Deal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offer Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _OfferChip(
                  label: 'Percent Off',
                  selected: _offerType == OfferType.percentOff,
                  onTap: () => setState(() => _offerType = OfferType.percentOff),
                ),
                const SizedBox(width: 8),
                _OfferChip(
                  label: 'Fixed Amount',
                  selected: _offerType == OfferType.fixedAmount,
                  onTap: () => setState(() => _offerType = OfferType.fixedAmount),
                ),
                const SizedBox(width: 8),
                _OfferChip(
                  label: 'Free Item',
                  selected: _offerType == OfferType.freeItem,
                  onTap: () => setState(() => _offerType = OfferType.freeItem),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Deal Details'),
            const SizedBox(height: 8),
            _buildTextField('Deal Title', controller: _titleController),
            const SizedBox(height: 12),
            if (_offerType == OfferType.percentOff)
              _buildTextField('Discount Percentage', controller: _discountController),
            const SizedBox(height: 12),
            _buildTextField(
              'Description',
              controller: _descriptionController,
              maxLines: 4,
              hint: 'Optional',
              maxLength: 2000,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Terms & Conditions (Optional)',
              controller: _termsController,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Deal Image'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  border: Border.all(color: AppColors.backgroundGrey),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: AppColors.brandPrimary),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add deal image',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Schedule'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTextField('Start Date', controller: _startDateController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('End Date', controller: _endDateController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Available Hours', controller: _startTimeController)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: _buildTextField('', controller: _endTimeController)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Available Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = _dayKeys[i];
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.textOnPrimary : AppColors.brandPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Publish Deal',
              onPressed: _publishDeal,
            ),
            const SizedBox(height: 12),
            AppOutlinedButton(
              text: 'Save As Draft',
              onPressed: _saveDraft,
              textColor: AppColors.brandPrimary,
              borderColor: AppColors.brandPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
    String? hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(
                hint,
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: AppColors.backgroundGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(color: AppColors.backgroundGrey),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (maxLength != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${controller.text.length}/$maxLength',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.brandPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

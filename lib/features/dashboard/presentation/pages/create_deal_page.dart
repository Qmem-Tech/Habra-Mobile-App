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
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<int> _selectedDays = {1, 2, 5, 6, 7};
  bool _showValidation = false;

  static const List<int> _dayKeys = [1, 2, 3, 4, 5, 6, 7];
  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _formatDate(DateTime? d) =>
      d != null ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' : '';

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final amPm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
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
    final validFrom = _startDate != null && _startTime != null
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute)
        : now;
    final validUntil = _endDate != null && _endTime != null
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute)
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
    final isTitleMissing = _titleController.text.trim().isEmpty;
    if (bizId == null || isTitleMissing) {
      setState(() => _showValidation = true);
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
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (result != null) {
        Navigator.pop(ctx, true);
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Could not create deal');
        }
      }
    }
  }

  Future<void> _saveDraft() async {
    final bizId = _getSelectedBusinessId();
    final isTitleMissing = _titleController.text.trim().isEmpty;
    if (bizId == null || isTitleMissing) {
      setState(() => _showValidation = true);
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
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      if (result != null) {
        Navigator.pop(ctx, true);
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Could not create deal');
        }
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
            _buildTextField(
              'Deal Title',
              controller: _titleController,
              isRequired: true,
              showError: _showValidation && _titleController.text.trim().isEmpty,
            ),
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
                Expanded(child: _buildDateField('Start Date', _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _buildDateField('End Date', _endDate, (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimeField('Start Time', _startTime, (t) => setState(() => _startTime = t))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: _buildTimeField('End Time', _endTime, (t) => setState(() => _endTime = t))),
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
            const SizedBox(height: 12),
            AppOutlinedButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
              textColor: AppColors.textSecondary,
              borderColor: AppColors.backgroundGrey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(String label, DateTime? current, void Function(DateTime) onPicked) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) onPicked(picked);
  }

  Future<void> _pickTime(String label, TimeOfDay? current, void Function(TimeOfDay) onPicked) async {
    final initial = current ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) onPicked(picked);
  }

  Widget _buildDateField(String label, DateTime? value, void Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickDate(label, value, onPicked),
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.brandPrimary),
                const SizedBox(width: 10),
                Text(
                  value != null ? _formatDate(value) : 'Tap to select',
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? value, void Function(TimeOfDay) onPicked) {
    final display = value != null
        ? _formatTimeOfDay(value)
        : 'Tap to select';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickTime(label, value, onPicked),
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppColors.brandPrimary),
                const SizedBox(width: 10),
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    bool isRequired = false,
    bool showError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isRequired ? '$label *' : label,
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
          onChanged: (_) {
            if (_showValidation) setState(() {});
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.backgroundGrey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.backgroundGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(
                color: showError ? AppColors.error : AppColors.brandPrimary,
              ),
            ),
            errorText: showError ? 'This field is required' : null,
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

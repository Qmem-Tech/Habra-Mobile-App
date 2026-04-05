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
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/dashboard_cubit.dart';
import '../../domain/entities/dashboard_deal.dart';

enum OfferType { percentOff, fixedAmount, freeItem }

class CreateDealPage extends StatefulWidget {
  const CreateDealPage({super.key, this.dealToEdit});

  /// When set, the page updates this deal instead of creating a new one.
  final DashboardDeal? dealToEdit;

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
  String? _pickedBusinessId;
  String? _existingImageUrl;

  bool get _isEditing => widget.dealToEdit != null;

  bool get _canPublishFromEdit {
    if (!_isEditing) return false;
    final s = widget.dealToEdit!.status;
    return s == DashboardDealStatus.inactive ||
        s == DashboardDealStatus.draft ||
        s == DashboardDealStatus.expired;
  }

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
  void initState() {
    super.initState();
    final d = widget.dealToEdit;
    if (d != null) {
      _prefillFromDeal(d);
    }
  }

  void _prefillFromDeal(DashboardDeal d) {
    _titleController.text = d.title;
    _descriptionController.text = d.description;
    final url = d.imageUrl;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      _existingImageUrl = url;
    }
    final cat = d.category ?? 'percent_off';
    if (cat == 'fixed_amount') {
      _offerType = OfferType.fixedAmount;
      if (d.discountedPrice != null) {
        _discountController.text = '${d.discountedPrice}';
      }
    } else if (cat == 'free_item') {
      _offerType = OfferType.freeItem;
      _discountController.clear();
    } else {
      _offerType = OfferType.percentOff;
      final pct = d.discountPercentage;
      if (pct != null && pct > 0) {
        _discountController.text = '$pct';
      }
    }
    if (d.validFrom != null) {
      final vf = d.validFrom!;
      _startDate = DateTime(vf.year, vf.month, vf.day);
      _startTime = TimeOfDay(hour: vf.hour, minute: vf.minute);
    }
    if (d.expiryDate != null) {
      final vu = d.expiryDate!;
      _endDate = DateTime(vu.year, vu.month, vu.day);
      _endTime = TimeOfDay(hour: vu.hour, minute: vu.minute);
    }
    _selectedDays
      ..clear()
      ..addAll(_dayKeys);
    _pickedBusinessId = d.businessId;
  }

  String _persistedStatusForEdit() {
    switch (widget.dealToEdit!.status) {
      case DashboardDealStatus.inactive:
        return 'inactive';
      case DashboardDealStatus.draft:
        return 'draft';
      case DashboardDealStatus.expired:
        return 'expired';
      case DashboardDealStatus.active:
        return 'active';
    }
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
    if (_pickedBusinessId != null) return _pickedBusinessId;
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      return homeState.selectedPresence!.id;
    }
    return null;
  }

  List<BusinessPresence> _getBusinesses() {
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded) {
      return homeState.presences.where((p) => p.id != 'all').toList();
    }
    return [];
  }

  bool get _needsBusinessPicker {
    if (_isEditing) return false;
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded) {
      return homeState.isAllBusinessesView || homeState.presences.length > 1;
    }
    return false;
  }

  DateTime? get _composedValidFrom {
    if (_startDate == null || _startTime == null) return null;
    return DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
  }

  DateTime? get _composedValidUntil {
    if (_endDate == null || _endTime == null) return null;
    return DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
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
    } else if (_existingImageUrl != null) {
      imageUrl = _existingImageUrl;
    }
    final now = DateTime.now();
    final validFrom = _composedValidFrom ?? now;
    final validUntil = _composedValidUntil ?? now.add(const Duration(days: 7));

    final discountRaw = _discountController.text.trim();
    final parsedDiscount = int.tryParse(discountRaw);
    late final String category;
    int? discountPercentage;
    int? discountedPrice;
    switch (_offerType) {
      case OfferType.percentOff:
        category = 'percent_off';
        discountPercentage = parsedDiscount;
        break;
      case OfferType.fixedAmount:
        category = 'fixed_amount';
        discountedPrice = parsedDiscount;
        break;
      case OfferType.freeItem:
        category = 'free_item';
        discountPercentage = 0;
        break;
    }

    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'discount_percentage': discountPercentage,
      'discounted_price': discountedPrice,
      'category': category,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'status': status,
      'image_url': imageUrl,
    };
  }

  List<String> _collectErrors({required bool forDraft}) {
    final errors = <String>[];
    if (_getSelectedBusinessId() == null) {
      errors.add('Please select a business');
    }
    if (_titleController.text.trim().isEmpty) {
      errors.add('Please enter a deal title');
    }
    if (forDraft) return errors;

    if (_descriptionController.text.trim().isEmpty) {
      errors.add('Please enter a deal description');
    }
    if (_composedValidFrom == null) {
      errors.add('Please select a start date and start time');
    }
    if (_composedValidUntil == null) {
      errors.add('Please select an end date and end time');
    }
    final from = _composedValidFrom;
    final until = _composedValidUntil;
    if (from != null && until != null && !until.isAfter(from)) {
      errors.add('End date and time must be after the start');
    }
    switch (_offerType) {
      case OfferType.percentOff:
        final pct = int.tryParse(_discountController.text.trim());
        if (pct == null || pct < 1 || pct > 100) {
          errors.add('Discount percentage must be between 1 and 100');
        }
        break;
      case OfferType.fixedAmount:
        final amt = int.tryParse(_discountController.text.trim());
        if (amt == null || amt < 1) {
          errors.add('Enter a whole dollar amount of at least 1');
        }
        break;
      case OfferType.freeItem:
        break;
    }
    if (_selectedDays.isEmpty) {
      errors.add('Select at least one available day');
    }
    return errors;
  }

  bool get _scheduleHasError {
    if (!_showValidation) return false;
    return _composedValidFrom == null ||
        _composedValidUntil == null ||
        (_composedValidFrom != null &&
            _composedValidUntil != null &&
            !_composedValidUntil!.isAfter(_composedValidFrom!));
  }

  Future<void> _submitEdit({required bool publish, bool asDraft = false}) async {
    final forDraft = asDraft;
    final errors = _collectErrors(forDraft: forDraft);
    if (errors.isNotEmpty) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final deal = widget.dealToEdit!;
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving...');
    try {
      final status = publish
          ? 'active'
          : (asDraft ? 'draft' : _persistedStatusForEdit());
      final payload = await _buildPayload(status);
      if (!ctx.mounted) return;
      final result = await ctx.read<DashboardCubit>().updateDeal(deal.id, payload);
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
          ErrorDisplayHelper.show(ctx, error: e, title: 'Could not save deal');
        }
      }
    }
  }

  Future<void> _saveEditedChanges() async {
    await _submitEdit(publish: false, asDraft: false);
  }

  Future<void> _publishDeal() async {
    if (_isEditing) {
      await _submitEdit(publish: true);
      return;
    }
    final errors = _collectErrors(forDraft: false);
    if (errors.isNotEmpty) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final bizId = _getSelectedBusinessId()!;
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
    if (_isEditing) {
      if (widget.dealToEdit!.status == DashboardDealStatus.draft) {
        await _submitEdit(publish: false, asDraft: true);
      }
      return;
    }
    final errors = _collectErrors(forDraft: true);
    if (errors.isNotEmpty) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final bizId = _getSelectedBusinessId()!;
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
      setState(() {
        _imageFile = file;
        _existingImageUrl = null;
      });
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
        title: Text(
          _isEditing ? 'Edit Deal' : 'Create Deal',
          style: const TextStyle(
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
            if (_needsBusinessPicker) ...[
              _buildBusinessPicker(),
              const SizedBox(height: 20),
            ],
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
                  onTap: () => setState(() {
                    _offerType = OfferType.percentOff;
                    _discountController.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _OfferChip(
                  label: 'Fixed Amount',
                  selected: _offerType == OfferType.fixedAmount,
                  onTap: () => setState(() {
                    _offerType = OfferType.fixedAmount;
                    _discountController.clear();
                  }),
                ),
                const SizedBox(width: 8),
                _OfferChip(
                  label: 'Free Item',
                  selected: _offerType == OfferType.freeItem,
                  onTap: () => setState(() {
                    _offerType = OfferType.freeItem;
                    _discountController.clear();
                  }),
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
              _buildTextField(
                'Discount Percentage',
                controller: _discountController,
                isRequired: true,
                showError: _showValidation && (() {
                  final pct = int.tryParse(_discountController.text.trim());
                  return pct == null || pct < 1 || pct > 100;
                })(),
                errorMessage: 'Enter a value between 1 and 100',
                keyboardType: TextInputType.number,
              ),
            if (_offerType == OfferType.fixedAmount)
              _buildTextField(
                'Amount off (\$)',
                controller: _discountController,
                isRequired: true,
                showError: _showValidation && (() {
                  final amt = int.tryParse(_discountController.text.trim());
                  return amt == null || amt < 1;
                })(),
                errorMessage: 'Enter a whole dollar amount of at least 1',
                keyboardType: TextInputType.number,
              ),
            if (_offerType == OfferType.freeItem)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Describe the free item in the description field below.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildTextField(
              'Description',
              controller: _descriptionController,
              maxLines: 4,
              isRequired: true,
              maxLength: 2000,
              showError: _showValidation && _descriptionController.text.trim().isEmpty,
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
                    : _existingImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppResources.radiusM),
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: AppColors.brandPrimary),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to replace image',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
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
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    _startDate,
                    (d) => setState(() => _startDate = d),
                    showError: _scheduleHasError,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    _endDate,
                    (d) => setState(() => _endDate = d),
                    showError: _scheduleHasError,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    'Start Time',
                    _startTime,
                    (t) => setState(() => _startTime = t),
                    showError: _scheduleHasError,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _buildTimeField(
                    'End Time',
                    _endTime,
                    (t) => setState(() => _endTime = t),
                    showError: _scheduleHasError,
                  ),
                ),
              ],
            ),
            if (_scheduleHasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Set all schedule fields so the offer ends after it starts.',
                  style: TextStyle(fontSize: 13, color: AppColors.error),
                ),
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
            if (_showValidation && _selectedDays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select at least one day this deal is available',
                  style: TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ),
            const SizedBox(height: 32),
            if (_isEditing) ...[
              AppButton(
                text: 'Save changes',
                onPressed: _saveEditedChanges,
              ),
              if (_canPublishFromEdit) ...[
                const SizedBox(height: 12),
                AppOutlinedButton(
                  text: 'Publish',
                  onPressed: _publishDeal,
                  textColor: AppColors.brandPrimary,
                  borderColor: AppColors.brandPrimary,
                ),
              ],
              if (widget.dealToEdit!.status == DashboardDealStatus.draft) ...[
                const SizedBox(height: 12),
                AppOutlinedButton(
                  text: 'Save As Draft',
                  onPressed: _saveDraft,
                  textColor: AppColors.brandPrimary,
                  borderColor: AppColors.brandPrimary,
                ),
              ],
            ] else ...[
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

  Widget _buildBusinessPicker() {
    final businesses = _getBusinesses();
    final effectiveId = _getSelectedBusinessId();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveId != null && businesses.any((b) => b.id == effectiveId) ? effectiveId : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(
                color: _showValidation && _getSelectedBusinessId() == null
                    ? AppColors.error
                    : AppColors.backgroundGrey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              borderSide: BorderSide(
                color: _showValidation && _getSelectedBusinessId() == null
                    ? AppColors.error
                    : AppColors.backgroundGrey,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorText: _showValidation && _getSelectedBusinessId() == null ? 'Please select a business' : null,
          ),
          hint: const Text('Select a business'),
          isExpanded: true,
          items: businesses
              .map((b) => DropdownMenuItem<String>(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => _pickedBusinessId = v),
        ),
      ],
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

  Widget _buildDateField(
    String label,
    DateTime? value,
    void Function(DateTime) onPicked, {
    bool showError = false,
  }) {
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
              border: Border.all(
                color: showError ? AppColors.error : AppColors.backgroundGrey,
              ),
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

  Widget _buildTimeField(
    String label,
    TimeOfDay? value,
    void Function(TimeOfDay) onPicked, {
    bool showError = false,
  }) {
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
              border: Border.all(
                color: showError ? AppColors.error : AppColors.backgroundGrey,
              ),
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
    String? errorMessage,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
            errorText: showError ? (errorMessage ?? 'This field is required') : null,
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

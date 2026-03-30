import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/widgets/location_picker_bottom_sheet.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../bloc/dashboard_cubit.dart';

class CreateJobPostPage extends StatefulWidget {
  const CreateJobPostPage({super.key});

  @override
  State<CreateJobPostPage> createState() => _CreateJobPostPageState();
}

class _CreateJobPostPageState extends State<CreateJobPostPage> {
  final _titleController = TextEditingController();
  final _jobTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  bool _isHourly = false;
  bool _remotePosition = true;
  bool _showValidation = false;
  String? _pickedBusinessId;

  @override
  void dispose() {
    _titleController.dispose();
    _jobTypeController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
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
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded) {
      return homeState.isAllBusinessesView || homeState.presences.length > 1;
    }
    return false;
  }

  Future<void> _openLocationPicker() async {
    final result = await LocationPickerBottomSheet.show(
      context,
      currentValue: _locationController.text.trim(),
    );
    if (result != null && mounted) {
      setState(() => _locationController.text = result);
    }
  }

  Map<String, dynamic> _buildPayload({String status = 'open'}) {
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : (_remotePosition ? 'Remote' : null),
      'job_type': _jobTypeController.text.trim().isNotEmpty
          ? _jobTypeController.text.trim().toLowerCase()
          : 'full-time',
      'salary_min': int.tryParse(_minSalaryController.text.trim()),
      'salary_max': int.tryParse(_maxSalaryController.text.trim()),
      'status': status,
    };
  }

  String? _validateForPost() {
    if (_getSelectedBusinessId() == null) return 'Please select a business';
    if (_titleController.text.trim().isEmpty) return 'Please enter a job title';
    if (_descriptionController.text.trim().isEmpty) return 'Please enter a job description';
    final minSalary = int.tryParse(_minSalaryController.text.trim());
    final maxSalary = int.tryParse(_maxSalaryController.text.trim());
    if (_minSalaryController.text.trim().isNotEmpty && minSalary == null) {
      return 'Minimum salary must be a number';
    }
    if (_maxSalaryController.text.trim().isNotEmpty && maxSalary == null) {
      return 'Maximum salary must be a number';
    }
    if (minSalary != null && maxSalary != null && minSalary > maxSalary) {
      return 'Minimum salary cannot exceed maximum salary';
    }
    return null;
  }

  Future<void> _postJob() async {
    final error = _validateForPost();
    if (error != null) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final bizId = _getSelectedBusinessId()!;
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Posting job...');
    String? errorMessage;
    bool success = false;
    try {
      final result = await ctx.read<DashboardCubit>().createJob(bizId, _buildPayload(status: 'open'));
      success = result != null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (success) {
      Navigator.pop(ctx, true);
    } else {
      ErrorDisplayHelper.show(
        ctx,
        message: errorMessage ?? 'We couldn\'t post your job. Please try again.',
        title: 'Post failed',
      );
    }
  }

  Future<void> _saveDraft() async {
    final bizId = _getSelectedBusinessId();
    final isTitleMissing = _titleController.text.trim().isEmpty;
    if (bizId == null || isTitleMissing) {
      setState(() => _showValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the job title and select a business')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Saving draft...');
    String? errorMessage;
    bool success = false;
    try {
      final result = await ctx.read<DashboardCubit>().createJob(bizId, _buildPayload(status: 'draft'));
      success = result != null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (success) {
      Navigator.pop(ctx, true);
    } else {
      ErrorDisplayHelper.show(
        ctx,
        message: errorMessage ?? 'We couldn\'t save your draft. Please try again.',
        title: 'Save failed',
      );
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
          'Create Job Post',
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
            if (_needsBusinessPicker) ...[
              _buildBusinessPicker(),
              const SizedBox(height: 20),
            ],
            _sectionTitle('Job Details'),
            const SizedBox(height: 12),
            _buildTextField(
              'Job Title',
              controller: _titleController,
              isRequired: true,
              showError: _showValidation && _titleController.text.trim().isEmpty,
            ),
            const SizedBox(height: 12),
            _buildTextField('Job Type', controller: _jobTypeController),
            const SizedBox(height: 12),
            _buildLocationField(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppResources.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote Position',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Is this job fully remote?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _remotePosition,
                    onChanged: (v) => setState(() => _remotePosition = v),
                    activeThumbColor: AppColors.brandPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Salary Range'),
                Row(
                  children: [
                    _SalaryTypeChip(
                      label: 'Hourly',
                      selected: _isHourly,
                      onTap: () => setState(() => _isHourly = true),
                    ),
                    const SizedBox(width: 8),
                    _SalaryTypeChip(
                      label: 'Yearly',
                      selected: !_isHourly,
                      onTap: () => setState(() => _isHourly = false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Minimum',
                    controller: _minSalaryController,
                    keyboardType: TextInputType.number,
                    showError: _showValidation &&
                        _minSalaryController.text.trim().isNotEmpty &&
                        int.tryParse(_minSalaryController.text.trim()) == null,
                    errorMessage: 'Must be a number',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _buildTextField(
                    'Maximum',
                    controller: _maxSalaryController,
                    keyboardType: TextInputType.number,
                    showError: _showValidation &&
                        _maxSalaryController.text.trim().isNotEmpty &&
                        int.tryParse(_maxSalaryController.text.trim()) == null,
                    errorMessage: 'Must be a number',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Job Description'),
            const SizedBox(height: 8),
            _buildTextField(
              'Description',
              controller: _descriptionController,
              maxLines: 5,
              isRequired: true,
              showError: _showValidation && _descriptionController.text.trim().isEmpty,
            ),
            const SizedBox(height: 24),
            _sectionTitle('Requirements'),
            const SizedBox(height: 8),
            _buildTextField(
              'Requirements (Optional)',
              controller: _requirementsController,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            AppButton(text: 'Post Job', onPressed: _postJob),
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
          value: effectiveId != null && businesses.any((b) => b.id == effectiveId) ? effectiveId : null,
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openLocationPicker,
          child: AbsorbPointer(
            child: TextField(
              controller: _locationController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select city or address...',
                filled: true,
                fillColor: AppColors.backgroundWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: const BorderSide(color: AppColors.backgroundGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  borderSide: const BorderSide(color: AppColors.backgroundGrey),
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
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
    bool isRequired = false,
    bool showError = false,
    String? errorMessage,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
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
      ],
    );
  }
}

class _SalaryTypeChip extends StatelessWidget {
  const _SalaryTypeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

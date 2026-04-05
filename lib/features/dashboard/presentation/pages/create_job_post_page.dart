import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/domain/business_address_data.dart';
import '../../../../core/widgets/street_address_field.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/permissions/app_permission.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/business_presence.dart';
import '../../../home/presentation/bloc/business_owner_home_cubit.dart';
import '../../../home/presentation/bloc/business_owner_home_state.dart';
import '../../domain/entities/dashboard_job.dart';
import '../bloc/dashboard_cubit.dart';

const _kJobTypeLabels = <String, String>{
  'full-time': 'Full-time',
  'part-time': 'Part-time',
  'contract': 'Contract',
  'internship': 'Internship',
};

class CreateJobPostPage extends StatefulWidget {
  const CreateJobPostPage({super.key, this.jobToEdit});

  final DashboardJob? jobToEdit;

  @override
  State<CreateJobPostPage> createState() => _CreateJobPostPageState();
}

class _CreateJobPostPageState extends State<CreateJobPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  String _jobTypeSlug = 'full-time';
  bool _isHourly = false;
  bool _remotePosition = true;
  double? _jobLat;
  double? _jobLng;
  bool _showValidation = false;
  /// When true, description/location use publish rules (min length, on-site location).
  bool _publishAttempted = false;
  String? _pickedBusinessId;

  bool get _editingPublished =>
      widget.jobToEdit != null && !widget.jobToEdit!.isDraft;

  @override
  void initState() {
    super.initState();
    final j = widget.jobToEdit;
    if (j != null) {
      _pickedBusinessId = j.businessId;
      _titleController.text = j.title;
      _jobTypeSlug = _coerceJobTypeSlug(j.jobTypeSlug);
      _remotePosition = j.isRemote;
      if (j.isRemote) {
        _locationController.text = '';
        _jobLat = null;
        _jobLng = null;
      } else {
        _locationController.text = j.location;
        _jobLat = j.latitude;
        _jobLng = j.longitude;
      }
      if (j.salaryMin != null) {
        _minSalaryController.text = '${j.salaryMin}';
      }
      if (j.salaryMax != null) {
        _maxSalaryController.text = '${j.salaryMax}';
      }
      _descriptionController.text = j.description ?? '';
      _requirementsController.text = j.requirements ?? '';
      _isHourly = j.salaryType == 'hourly';
    }
  }

  String _coerceJobTypeSlug(String slug) {
    final n = DashboardJob.normalizeJobTypeSlug(slug);
    return _kJobTypeLabels.containsKey(n) ? n : 'full-time';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  String? _getSelectedBusinessId() {
    if (widget.jobToEdit != null) return widget.jobToEdit!.businessId;
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
    if (widget.jobToEdit != null) return false;
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded) {
      return homeState.isAllBusinessesView || homeState.presences.length > 1;
    }
    return false;
  }

  static String _formatWorkAddressLine(BusinessAddressData d) {
    final parts = <String>[
      if (d.street != null && d.street!.isNotEmpty) d.street!,
      if (d.suite != null && d.suite!.isNotEmpty) d.suite!,
      if (d.city != null && d.city!.isNotEmpty) d.city!,
      if (d.state != null && d.state!.isNotEmpty) d.state!,
      if (d.zipCode != null && d.zipCode!.isNotEmpty) d.zipCode!,
    ];
    return parts.isEmpty ? 'Selected location' : parts.join(', ');
  }

  void _applyWorkAddress(BusinessAddressData data) {
    setState(() {
      _locationController.text = _formatWorkAddressLine(data);
      if (data.hasCoordinates) {
        _jobLat = data.latitude;
        _jobLng = data.longitude;
      }
    });
  }

  Map<String, dynamic> _buildPayload({required String status}) {
    final requirements = _requirementsController.text.trim();
    final remote = _remotePosition;
    final locText = _locationController.text.trim();
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': remote
          ? 'Remote'
          : (locText.isNotEmpty ? locText : null),
      'job_type': _jobTypeSlug,
      'salary_min': int.tryParse(_minSalaryController.text.trim()),
      'salary_max': int.tryParse(_maxSalaryController.text.trim()),
      'salary_type': _isHourly ? 'hourly' : 'yearly',
      'is_remote': remote,
      if (!remote && _jobLat != null && _jobLng != null) 'location_lat': _jobLat,
      if (!remote && _jobLat != null && _jobLng != null) 'location_lng': _jobLng,
      if (requirements.isNotEmpty) 'requirements': requirements,
      'status': status,
    };
  }

  String _statusPayloadForExistingJob() {
    final j = widget.jobToEdit!;
    switch (j.status) {
      case DashboardJobStatus.draft:
        return 'draft';
      case DashboardJobStatus.closed:
        return 'closed';
      case DashboardJobStatus.open:
        return 'open';
    }
  }

  List<String> _salaryFieldErrors() {
    final errors = <String>[];
    final minText = _minSalaryController.text.trim();
    final maxText = _maxSalaryController.text.trim();
    final minSalary = int.tryParse(minText);
    final maxSalary = int.tryParse(maxText);
    if (minText.isNotEmpty && minSalary == null) {
      errors.add('Minimum salary must be a valid number');
    }
    if (maxText.isNotEmpty && maxSalary == null) {
      errors.add('Maximum salary must be a valid number');
    }
    if (minSalary != null && maxSalary != null && minSalary > maxSalary) {
      errors.add('Minimum salary cannot exceed maximum salary');
    }
    return errors;
  }

  List<String> _collectPublishErrors() {
    final errors = <String>[];
    if (_getSelectedBusinessId() == null) {
      errors.add('Please select a business');
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      errors.add('Please enter a job title');
    } else if (title.length > 120) {
      errors.add('Job title must be 120 characters or less');
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      errors.add('Please enter a job description');
    } else if (desc.length < 30) {
      errors.add('Description should be at least 30 characters to publish');
    }
    if (!_remotePosition) {
      if (_locationController.text.trim().isEmpty) {
        errors.add('Enter a work location or enable remote');
      } else if (_jobLat == null || _jobLng == null) {
        errors.add(
          'Choose an address from search suggestions or use current location '
          'so the job has map coordinates.',
        );
      }
    }
    errors.addAll(_salaryFieldErrors());
    return errors;
  }

  List<String> _collectDraftErrors() {
    final errors = <String>[];
    if (_getSelectedBusinessId() == null) {
      errors.add('Please select a business');
    }
    if (_titleController.text.trim().isEmpty) {
      errors.add('Please enter a job title');
    }
    final title = _titleController.text.trim();
    if (title.length > 120) {
      errors.add('Job title must be 120 characters or less');
    }
    errors.addAll(_salaryFieldErrors());
    return errors;
  }

  bool get _isSalaryRangeInvalid {
    final min = int.tryParse(_minSalaryController.text.trim());
    final max = int.tryParse(_maxSalaryController.text.trim());
    return min != null && max != null && min > max;
  }

  bool get _titleInvalid {
    final t = _titleController.text.trim();
    return t.isEmpty || t.length > 120;
  }

  bool get _descriptionPublishInvalid {
    final t = _descriptionController.text.trim();
    return t.isEmpty || t.length < 30;
  }

  bool get _locationPublishInvalid =>
      !_remotePosition &&
      (_locationController.text.trim().isEmpty ||
          _jobLat == null ||
          _jobLng == null);

  Future<void> _postJob() async {
    final errors = _collectPublishErrors();
    if (errors.isNotEmpty) {
      setState(() {
        _showValidation = true;
        _publishAttempted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final bizId = _getSelectedBusinessId()!;
    final ctx = context;
    final editing = widget.jobToEdit;
    LoaderHelper.show(
      ctx,
      message: editing != null ? 'Publishing…' : 'Posting job…',
    );
    String? errorMessage;
    DashboardJob? result;
    try {
      if (editing != null) {
        result = await ctx
            .read<DashboardCubit>()
            .updateJob(editing.id, _buildPayload(status: 'open'));
      } else {
        result = await ctx
            .read<DashboardCubit>()
            .createJob(bizId, _buildPayload(status: 'open'));
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (result != null) {
      Navigator.pop(ctx, true);
    } else {
      ErrorDisplayHelper.show(
        ctx,
        message: errorMessage ??
            'We couldn\'t publish this job. Please try again.',
        title: 'Publish failed',
      );
    }
  }

  Future<void> _saveDraft() async {
    final errors = _collectDraftErrors();
    if (errors.isNotEmpty) {
      setState(() {
        _showValidation = true;
        _publishAttempted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final bizId = _getSelectedBusinessId()!;
    final ctx = context;
    final editing = widget.jobToEdit;
    LoaderHelper.show(ctx, message: 'Saving draft…');
    String? errorMessage;
    DashboardJob? result;
    try {
      if (editing != null) {
        result = await ctx
            .read<DashboardCubit>()
            .updateJob(editing.id, _buildPayload(status: 'draft'));
      } else {
        result = await ctx
            .read<DashboardCubit>()
            .createJob(bizId, _buildPayload(status: 'draft'));
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (result != null) {
      Navigator.pop(ctx, true);
    } else {
      ErrorDisplayHelper.show(
        ctx,
        message: errorMessage ??
            'We couldn\'t save your draft. Please try again.',
        title: 'Save failed',
      );
    }
  }

  Future<void> _savePublishedChanges() async {
    final errors = _collectPublishErrors();
    if (errors.isNotEmpty) {
      setState(() {
        _showValidation = true;
        _publishAttempted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }
    final ctx = context;
    final job = widget.jobToEdit!;
    LoaderHelper.show(ctx, message: 'Saving changes…');
    String? errorMessage;
    DashboardJob? result;
    try {
      result = await ctx.read<DashboardCubit>().updateJob(
            job.id,
            _buildPayload(status: _statusPayloadForExistingJob()),
          );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (result != null) {
      Navigator.pop(ctx, true);
    } else {
      ErrorDisplayHelper.show(
        ctx,
        message: errorMessage ??
            'We couldn\'t save your changes. Please try again.',
        title: 'Update failed',
      );
    }
  }

  String _appBarTitle() {
    if (widget.jobToEdit == null) return 'Create Job Post';
    return widget.jobToEdit!.isDraft ? 'Edit Job Post' : 'Edit Job';
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
          _appBarTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                showError: _showValidation && _titleInvalid,
                errorMessage: _titleController.text.trim().isEmpty
                    ? null
                    : (_titleController.text.trim().length > 120
                        ? 'Max 120 characters'
                        : null),
              ),
              const SizedBox(height: 12),
              _buildJobTypeDropdown(),
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
                      onChanged: (v) => setState(() {
                        _remotePosition = v;
                        if (v) {
                          _jobLat = null;
                          _jobLng = null;
                          _locationController.clear();
                        }
                      }),
                      activeThumbColor: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
              if (!_remotePosition) ...[
                const SizedBox(height: 12),
                _buildWorkLocationSection(),
              ],
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
                          ((_minSalaryController.text.trim().isNotEmpty &&
                                  int.tryParse(
                                          _minSalaryController.text.trim()) ==
                                      null) ||
                              _isSalaryRangeInvalid),
                      errorMessage: _minSalaryController.text.trim().isNotEmpty &&
                              int.tryParse(_minSalaryController.text.trim()) ==
                                  null
                          ? 'Must be a number'
                          : (_isSalaryRangeInvalid ? 'Min exceeds max' : null),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'to',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTextField(
                      'Maximum',
                      controller: _maxSalaryController,
                      keyboardType: TextInputType.number,
                      showError: _showValidation &&
                          ((_maxSalaryController.text.trim().isNotEmpty &&
                                  int.tryParse(
                                          _maxSalaryController.text.trim()) ==
                                      null) ||
                              _isSalaryRangeInvalid),
                      errorMessage: _maxSalaryController.text.trim().isNotEmpty &&
                              int.tryParse(_maxSalaryController.text.trim()) ==
                                  null
                          ? 'Must be a number'
                          : null,
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
                showError: _showValidation &&
                    _publishAttempted &&
                    _descriptionPublishInvalid,
                errorMessage: _descriptionController.text.trim().isEmpty
                    ? null
                    : (_descriptionController.text.trim().length < 30
                        ? 'At least 30 characters to publish'
                        : null),
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
              if (_editingPublished) ...[
                AppButton(
                  text: 'Save changes',
                  onPressed: _savePublishedChanges,
                ),
              ] else ...[
                AppButton(
                  text: widget.jobToEdit != null ? 'Publish' : 'Post Job',
                  onPressed: _postJob,
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
      ),
    );
  }

  Widget _buildJobTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _jobTypeSlug,
          decoration: InputDecoration(
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          isExpanded: true,
          items: _kJobTypeLabels.entries
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _jobTypeSlug = v ?? 'full-time'),
        ),
      ],
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveId != null &&
                  businesses.any((b) => b.id == effectiveId)
              ? effectiveId
              : null,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorText: _showValidation && _getSelectedBusinessId() == null
                ? 'Please select a business'
                : null,
          ),
          hint: const Text('Select a business'),
          isExpanded: true,
          items: businesses
              .map(
                (b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(b.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _pickedBusinessId = v),
        ),
      ],
    );
  }

  Widget _buildWorkLocationSection() {
    final hasCoords = _jobLat != null && _jobLng != null;
    final showLocError =
        _showValidation && _publishAttempted && _locationPublishInvalid;
    final borderColor =
        showLocError ? AppColors.error : AppColors.backgroundGrey;
    final decoration = InputDecoration(
      filled: true,
      fillColor: AppColors.backgroundWhite,
      errorText: showLocError
          ? (_locationController.text.trim().isEmpty
              ? 'Required when not remote'
              : 'Pick a suggestion or use current location for coordinates')
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        borderSide: BorderSide(color: borderColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work location *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        StreetAddressField(
          controller: _locationController,
          hintText: 'Street, city, state — pick a suggestion or use search',
          decoration: decoration,
          onAddressPicked: _applyWorkAddress,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Pick a result from suggestions or address search to save latitude and longitude.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Or use device location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final granted = await di.sl<PermissionService>().requestWithDialog(
                    context,
                    AppPermission.location,
                  );
              if (!granted || !mounted) return;
              final result =
                  await di.sl<LocationService>().getCurrentLocationAsAddress();
              if (!mounted) return;
              result.fold(
                (f) => ErrorDisplayHelper.show(
                  context,
                  message: f.message,
                  title: 'Location',
                ),
                (data) {
                  _applyWorkAddress(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address set from current location'),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use current location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              side: BorderSide(color: AppColors.brandPrimary),
            ),
          ),
        ),
        if (hasCoords)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Map coordinates saved for this job location.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
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
            errorText:
                showError ? (errorMessage ?? 'This field is required') : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

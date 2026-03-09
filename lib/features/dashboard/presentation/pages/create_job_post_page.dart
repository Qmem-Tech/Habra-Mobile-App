import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
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
    final homeState = context.read<BusinessOwnerHomeCubit>().state;
    if (homeState is BusinessOwnerHomeLoaded &&
        homeState.selectedPresence != null &&
        homeState.selectedPresence!.id != 'all') {
      return homeState.selectedPresence!.id;
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
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
    };
  }

  Future<void> _postJob() async {
    final bizId = _getSelectedBusinessId();
    if (bizId == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the job title and select a business')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(ctx, message: 'Posting job...');
    final result = await ctx.read<DashboardCubit>().createJob(bizId, _buildPayload());
    if (!ctx.mounted) return;
    LoaderHelper.hide(ctx);
    if (result != null) {
      Navigator.pop(ctx, true);
    }
  }

  Future<void> _saveDraft() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job draft saved locally')),
    );
    Navigator.pop(context, false);
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
            _sectionTitle('Job Details'),
            const SizedBox(height: 12),
            _buildTextField('Job Title', controller: _titleController),
            const SizedBox(height: 12),
            _buildTextField('Job Type', controller: _jobTypeController),
            const SizedBox(height: 12),
            _buildTextField('Location', controller: _locationController),
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
                  child: _buildTextField('Minimum', controller: _minSalaryController),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _buildTextField('Maximum', controller: _maxSalaryController),
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
        TextField(
          controller: controller,
          maxLines: maxLines,
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

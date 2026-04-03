import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../bloc/job_applications_cubit.dart';
import '../bloc/job_applications_state.dart';
import 'application_submitted_page.dart';

bool _looksLikeValidEmail(String email) {
  final v = email.trim();
  if (v.isEmpty) return false;
  if (v.length > 254) return false;
  final re = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  return re.hasMatch(v);
}

String? _validateFullNameField(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) {
    return 'Please enter your full name';
  }
  if (v.length < 2) {
    return 'Name is too short';
  }
  if (v.length > 120) {
    return 'Name must be at most 120 characters';
  }
  if (!RegExp(r'[a-zA-Z\u00C0-\u024F\u0400-\u04FF]').hasMatch(v)) {
    return 'Please use letters for your name';
  }
  final parts = v.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) {
    return 'Please enter your first and last name';
  }
  return null;
}

String? _validateEmailField(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) {
    return 'Please enter your email';
  }
  if (!_looksLikeValidEmail(v)) {
    return 'Please enter a valid email address';
  }
  return null;
}

class ApplyForJobPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String companyName;

  const ApplyForJobPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
  });

  @override
  State<ApplyForJobPage> createState() => _ApplyForJobPageState();
}

class _ApplyForJobPageState extends State<ApplyForJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _coverLetterController = TextEditingController();

  String _phoneNumber = '';
  File? _resumeFile;
  String? _selectedScreeningAnswer;

  @override
  void initState() {
    super.initState();
    _coverLetterController.addListener(() {
      if (mounted) setState(() {});
    });
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _fullNameController.text = authState.user.name;
      _emailController.text = authState.user.email;
      final result = await di.sl<ProfileRepository>().getProfile(authState.user.id);
      result.fold(
        (_) {},
        (profile) {
          if (profile.phone != null && profile.phone!.isNotEmpty) {
            _phoneNumber = profile.phone!;
          }
        },
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final ctx = context;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: false,
    );
    if (!ctx.mounted) return;
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (!ctx.mounted) return;
        ErrorDisplayHelper.show(ctx, message: 'File must be under 5MB', title: 'File too large');
        return;
      }
      setState(() => _resumeFile = file);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedScreeningAnswer == null) {
      ErrorDisplayHelper.show(
        context,
        message: 'Please answer the screening question.',
        title: 'Almost there',
      );
      return;
    }
    if (_selectedScreeningAnswer == 'No') {
      ErrorDisplayHelper.show(
        context,
        message:
            'This role requires legal authorization to work in the United States. '
            'You can still browse other opportunities on Habra.',
        title: 'Work authorization',
      );
      return;
    }
    if (_resumeFile == null) {
      ErrorDisplayHelper.show(
        context,
        message: 'Please upload a resume (PDF, DOC, or DOCX, max 5MB).',
        title: 'Resume required',
      );
      return;
    }
    final phoneDigits = _phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 8) {
      ErrorDisplayHelper.show(
        context,
        message: 'Please enter a complete phone number including country/area code.',
        title: 'Invalid phone',
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ErrorDisplayHelper.show(context, message: 'Please sign in to apply', title: 'Sign in required');
      return;
    }

    final (url, error) = await context.read<JobApplicationsCubit>().uploadResume(
          userId,
          widget.jobId,
          _resumeFile!,
        );
    if (url == null && mounted) {
      ErrorDisplayHelper.show(
        context,
        message: error ?? 'Failed to upload resume. Please try again.',
        title: 'Upload failed',
      );
      return;
    }
    final resumeUrl = url;

    if (!mounted) return;
    final cover = _coverLetterController.text.trim();
    context.read<JobApplicationsCubit>().submitApplication(
          jobId: widget.jobId,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneNumber.trim(),
          resumeUrl: resumeUrl,
          coverLetter: cover.isEmpty ? null : cover,
          photoUrl: null,
          screeningAnswers: _selectedScreeningAnswer != null
              ? {
                  'Are you legally authorized to work in the United States?':
                      _selectedScreeningAnswer!,
                }
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobApplicationsCubit, JobApplicationsState>(
        listener: (context, state) {
          if (state is SubmitApplicationSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicationSubmittedPage(
                  jobTitle: widget.jobTitle,
                  companyName: widget.companyName,
                ),
              ),
            );
          } else if (state is SubmitApplicationError) {
            ErrorDisplayHelper.show(context, message: state.message, title: 'Application failed');
          }
        },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Apply for Job'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobInfoCard(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
                  const SizedBox(height: 24),
                  _buildResumeSection(),
                  const SizedBox(height: 24),
                  _buildCoverLetterSection(),
                  const SizedBox(height: 24),
                  _buildScreeningQuestions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BlocBuilder<JobApplicationsCubit,
              JobApplicationsState>(
            builder: (context, state) {
              final isLoading = state is SubmitApplicationLoading;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Submit Application',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildJobInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimaryLight.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.jobTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@ ${widget.companyName}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: _validateFullNameField,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          maxLength: 254,
          validator: _validateEmailField,
        ),
        const SizedBox(height: 16),
        IntlPhoneField(
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          initialCountryCode: 'US',
          invalidNumberMessage: 'Enter a valid phone number',
          onChanged: (phone) {
            setState(() => _phoneNumber = phone.completeNumber);
          },
          validator: (value) {
            if (value == null || value.number.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            final complete = value.completeNumber;
            final digits = complete.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 8) {
              return 'Phone number looks incomplete';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Resume / CV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Required',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickResume,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryLight.withValues(alpha:0.1),
              border: Border.all(
                color: AppColors.brandPrimary,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click to upload or drag and drop',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, DOC, DOCX (Max 5MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_resumeFile != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Selected: ${_resumeFile!.path.split('/').last}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverLetterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Cover Letter',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _coverLetterController,
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Write your cover letter here...',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          validator: (value) {
            final v = value ?? '';
            if (v.length > 2000) {
              return 'Cover letter must be at most 2000 characters';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_coverLetterController.text.length}/2000',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreeningQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screening Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Are you legally authorized to work in the United States?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildScreeningOption(
                'Yes',
                _selectedScreeningAnswer == 'Yes',
                () {
                  setState(() {
                    _selectedScreeningAnswer = 'Yes';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScreeningOption(
                'No',
                _selectedScreeningAnswer == 'No',
                () {
                  setState(() {
                    _selectedScreeningAnswer = 'No';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScreeningOption(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimaryLight.withValues(alpha:0.2)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.backgroundGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

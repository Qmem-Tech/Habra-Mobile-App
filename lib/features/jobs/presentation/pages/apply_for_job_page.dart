import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/job_applications_cubit.dart';
import '../bloc/job_applications_state.dart';
import 'application_submitted_page.dart';

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
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  String? _resumePath;
  String? _selectedScreeningAnswer;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    // TODO: Implement file picker when ready
    // For now, show a dialog to simulate file selection
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Upload'),
        content: const Text(
          'File picker will be implemented later. For now, you can proceed without uploading a resume.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'mock'),
            child: const Text('Use Mock File'),
          ),
        ],
      ),
    );

    if (result == 'mock') {
      setState(() {
        _resumePath = 'mock_resume.pdf';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock resume file selected'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _submitApplication() {
    if (!_formKey.currentState!.validate()) return;

    context.read<JobApplicationsCubit>().submitApplication(
          jobId: widget.jobId,
          fullName: _fullNameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          resumeUrl: _resumePath,
          coverLetter: _coverLetterController.text.isEmpty
              ? null
              : _coverLetterController.text,
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
    return BlocProvider(
      create: (context) => di.sl<JobApplicationsCubit>(),
      child: BlocListener<JobApplicationsCubit, JobApplicationsState>(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                      color: Colors.black.withOpacity(0.1),
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
      ),
    );
  }

  Widget _buildJobInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimaryLight.withOpacity(0.1),
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
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
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
        const Text(
          'Resume / CV',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickResume,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryLight.withOpacity(0.1),
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
                if (_resumePath != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Selected: ${_resumePath!.split('/').last}',
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
              ? AppColors.brandPrimaryLight.withOpacity(0.2)
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

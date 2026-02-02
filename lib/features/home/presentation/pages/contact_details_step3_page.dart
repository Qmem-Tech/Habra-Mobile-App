import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import 'add_photos_step4_page.dart';

/// Contact Details step 3: Phone, Email, Website (optional), Business hours, Next.
class ContactDetailsStep3Page extends StatefulWidget {
  const ContactDetailsStep3Page({super.key});

  @override
  State<ContactDetailsStep3Page> createState() =>
      _ContactDetailsStep3PageState();
}

class _ContactDetailsStep3PageState extends State<ContactDetailsStep3Page> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;

  static const List<({String day, String hours})> _defaultHours = [
    (day: 'Monday', hours: '9:00 AM - 5:00 PM'),
    (day: 'Tuesday', hours: '9:00 AM - 5:00 PM'),
    (day: 'Wednesday', hours: '9:00 AM - 5:00 PM'),
    (day: 'Thursday', hours: '9:00 AM - 5:00 PM'),
    (day: 'Friday', hours: '9:00 AM - 5:00 PM'),
    (day: 'Saturday', hours: '10:00 AM - 4:00 PM'),
    (day: 'Sunday', hours: 'Closed'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isActive = i <= 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandPrimary : AppColors.progressInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Business Phone'),
              const SizedBox(height: 8),
              _buildTextField(_phoneController, 'Phone number'),
              const SizedBox(height: 16),
              _buildLabel('Business Email'),
              const SizedBox(height: 8),
              _buildTextField(_emailController, 'Email'),
              const SizedBox(height: 16),
              _buildLabel('Website (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(_websiteController, 'https://'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Business',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.edit, size: 18, color: AppColors.brandSecondary),
                    label: Text(
                      'Edit Hours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._defaultHours.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.day,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: e.hours == 'Closed'
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                )
                              : null,
                          decoration: e.hours == 'Closed'
                              ? BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                )
                              : null,
                          child: Text(
                            e.hours,
                            style: TextStyle(
                              fontSize: 14,
                              color: e.hours == 'Closed'
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Next',
            onPressed: _isLoading ? null : _onNext,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          borderSide: BorderSide(color: AppColors.backgroundGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          borderSide: BorderSide(color: AppColors.backgroundGrey),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _onNext() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPhotosStep4Page(),
      ),
    );
  }
}

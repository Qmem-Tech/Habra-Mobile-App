import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import 'business_location_step2_page.dart';

/// Business Details step 1: Business Name, Business Category, Next.
class BusinessDetailsStep1Page extends StatefulWidget {
  const BusinessDetailsStep1Page({super.key});

  @override
  State<BusinessDetailsStep1Page> createState() =>
      _BusinessDetailsStep1PageState();
}

class _BusinessDetailsStep1PageState extends State<BusinessDetailsStep1Page> {
  final _nameController = TextEditingController(text: 'Amma');
  final _categoryController = TextEditingController(text: 'Restaurant & Cafe');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
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
            final isActive = i == 0;
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
                'Business Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Business Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter business name',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: BorderSide(color: AppColors.backgroundGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: BorderSide(color: AppColors.backgroundGrey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Business Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Select category',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: BorderSide(color: AppColors.backgroundGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    borderSide: BorderSide(color: AppColors.backgroundGrey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onTap: () {
                  // TODO: Open category picker
                },
              ),
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

  Future<void> _onNext() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BusinessLocationStep2Page(),
      ),
    );
  }
}

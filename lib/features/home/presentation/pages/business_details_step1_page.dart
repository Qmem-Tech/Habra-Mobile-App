import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/validation/business_onboarding_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../explore/domain/entities/listing_category.dart';
import '../../../explore/domain/usecases/get_active_listing_categories_usecase.dart';
import 'business_location_step2_page.dart';

/// Business Details step 1: Business Name, listing category from Supabase, Next.
class BusinessDetailsStep1Page extends StatefulWidget {
  const BusinessDetailsStep1Page({super.key});

  @override
  State<BusinessDetailsStep1Page> createState() =>
      _BusinessDetailsStep1PageState();
}

class _BusinessDetailsStep1PageState extends State<BusinessDetailsStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedCategoryId;
  List<ListingCategory> _listingCategories = [];
  bool _listingCategoriesLoading = true;
  String? _listingCategoriesError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadListingCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadListingCategories() async {
    final result = await di.sl<GetActiveListingCategoriesUseCase>()();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _listingCategoriesError = failure.message;
        _listingCategoriesLoading = false;
      }),
      (list) => setState(() {
        _listingCategories = list;
        _listingCategoriesLoading = false;
        _listingCategoriesError =
            list.isEmpty ? 'No categories are available yet.' : null;
      }),
    );
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
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _nameController,
                  maxLength: BusinessOnboardingValidators.businessNameMaxLength,
                  buildCounter: (
                    BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) =>
                      const SizedBox.shrink(),
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      borderSide: const BorderSide(color: AppColors.brandPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: BusinessOnboardingValidators.businessName,
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
                if (_listingCategoriesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_listingCategoriesError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _listingCategoriesError!,
                          style: TextStyle(color: AppColors.error, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _listingCategoriesLoading = true;
                              _listingCategoriesError = null;
                            });
                            _loadListingCategories();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use - use initialValue when form API is updated
                    value: _selectedCategoryId,
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        borderSide: const BorderSide(color: AppColors.brandPrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: _listingCategories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a business category';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Next',
            onPressed: (_isLoading ||
                    _listingCategoriesLoading ||
                    _listingCategoriesError != null ||
                    _listingCategories.isEmpty)
                ? null
                : _onNext,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessLocationStep2Page(
          step1Data: {
            'name': _nameController.text.trim(),
            'category_id': categoryId,
          },
        ),
      ),
    );
  }
}

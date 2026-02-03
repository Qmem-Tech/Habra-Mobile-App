import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/datasources/mock_data/mock_business_owner_data.dart';
import '../../domain/entities/business_brand_entity.dart';
import 'add_location_page.dart';

/// Choose the business brand for a new location (Add New Presence → New Location flow).
/// Step 1 of 2: search + list with Select, then Next.
class ChooseBusinessBrandPage extends StatefulWidget {
  const ChooseBusinessBrandPage({super.key});

  @override
  State<ChooseBusinessBrandPage> createState() => _ChooseBusinessBrandPageState();
}

class _ChooseBusinessBrandPageState extends State<ChooseBusinessBrandPage> {
  final _searchController = TextEditingController();
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BusinessBrandEntity> get _filteredBrands {
    final all = MockBusinessOwnerData.getMockBusinessBrands();
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final brands = _filteredBrands;

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
          children: [
            _stepDot(active: true),
            const SizedBox(width: 6),
            _stepDot(active: false),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Choose the business brand for this new location.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
                itemCount: brands.length,
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  final isSelected = _selectedBrandId == brand.id;
                  return _buildBrandCard(brand, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Next',
            onPressed: _selectedBrandId == null ? null : () => _onNext(context),
          ),
        ),
      ),
    );
  }

  Widget _stepDot({required bool active}) {
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : AppColors.progressInactive,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search businesses...',
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
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

  Widget _buildBrandCard(BusinessBrandEntity brand, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        border: Border.all(
          color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
            ),
            child: Icon(Icons.store, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      brand.activeLocationsLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            child: TextButton(
              onPressed: () => setState(() => _selectedBrandId = brand.id),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Select'),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext(BuildContext context) {
    if (_selectedBrandId == null) return;
    final brands = MockBusinessOwnerData.getMockBusinessBrands();
    final brand = brands.firstWhere((b) => b.id == _selectedBrandId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLocationPage(selectedBrand: brand),
      ),
    );
  }
}

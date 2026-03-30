import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/location_picker_bottom_sheet.dart';
import 'interests_selection_page.dart';

class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  final List<String> _cities = kPopularUSCities;
  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = _cities;
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _cities
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onContinue() {
    if (_selectedCity != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const InterestsSelectionPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppResources.spacingL,
                vertical: AppResources.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Select your city',
                    style: AppFonts.largeTitle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppResources.spacingL),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search city, zip code...',
                      hintStyle: AppFonts.body(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
                        borderSide: BorderSide(color: AppColors.backgroundGrey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // City list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  final isSelected = _selectedCity == city;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppResources.spacingM,
                        vertical: AppResources.spacingL,
                      ),
                      margin: const EdgeInsets.only(bottom: AppResources.spacingS),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandPrimary : AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            city,
                            style: AppFonts.body(
                              color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: AppColors.textOnPrimary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppResources.spacingL),
              child: SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

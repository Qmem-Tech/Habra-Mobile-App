import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/job_quick_filter_options.dart';

class JobFiltersBottomSheet extends StatefulWidget {
  final JobFilters? initialFilters;

  const JobFiltersBottomSheet({
    super.key,
    this.initialFilters,
  });

  @override
  State<JobFiltersBottomSheet> createState() =>
      _JobFiltersBottomSheetState();
}

class _JobFiltersBottomSheetState extends State<JobFiltersBottomSheet> {
  late JobFilters _filters;
  final List<String> _categories = [
    'Homecare',
    'Trucking',
    'Retail',
    'Construction',
    'Healthcare',
  ];
  final List<String> _jobTypes = List<String>.from(kJobsQuickFilterJobTypes);
  final List<String> _dateRanges = [
    'Today',
    'Past 3 Days',
    'Past Week',
    'Anytime',
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const JobFilters();
  }

  void _toggleCategory(String category) {
    setState(() {
      final categories = List<String>.from(_filters.categories);
      if (categories.contains(category)) {
        categories.remove(category);
      } else {
        categories.add(category);
      }
      _filters = _filters.copyWith(categories: categories);
    });
  }

  void _toggleJobType(String jobType) {
    setState(() {
      final jobTypes = List<String>.from(_filters.jobTypes);
      if (jobTypes.contains(jobType)) {
        jobTypes.remove(jobType);
      } else {
        jobTypes.add(jobType);
      }
      _filters = _filters.copyWith(jobTypes: jobTypes);
    });
  }

  void _selectDateRange(String dateRange) {
    setState(() {
      _filters = _filters.copyWith(
        dateRange: _filters.dateRange == dateRange ? null : dateRange,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = const JobFilters();
                    });
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobCategorySection(),
                  const SizedBox(height: 24),
                  _buildJobTypeSection(),
                  const SizedBox(height: 24),
                  _buildDateRangeSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Button
          Container(
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
                  onPressed: () {
                    Navigator.pop(context, _filters);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply filters',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._categories.map((category) {
          final isSelected = _filters.categories.contains(category);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _toggleCategory(category),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.backgroundGrey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJobTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._jobTypes.map((jobType) {
          final isSelected = _filters.jobTypes.contains(jobType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _toggleJobType(jobType),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.backgroundGrey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    jobType,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._dateRanges.map((dateRange) {
          final isSelected = _filters.dateRange == dateRange;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _selectDateRange(dateRange),
              child: Container(
                padding: const EdgeInsets.all(12),
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
                      dateRange,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

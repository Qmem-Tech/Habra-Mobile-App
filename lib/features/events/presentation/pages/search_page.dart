import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;

  const SearchPage({
    super.key,
    this.initialQuery = '',
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _quickSearches = const [
    'Concert',
    'Party',
    'Cultural',
    'Community',
    'Networking',
  ];

  void _applyAndClose() {
    Navigator.pop(context, _searchController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery.trim();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search events...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: (_) => _applyAndClose(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchController.text.trim().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.backgroundGrey.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Press search on keyboard or tap Apply to filter events.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
              )
            else
              Text(
                'Quick searches',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withValues(alpha: 0.95),
                ),
              ),
            const SizedBox(height: 12),
            if (_searchController.text.trim().isEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSearches.map((keyword) {
                  return ActionChip(
                    label: Text(keyword),
                    onPressed: () {
                      _searchController.text = keyword;
                      _applyAndClose();
                    },
                    backgroundColor: AppColors.backgroundLight,
                    side: BorderSide(
                      color: AppColors.backgroundGrey.withValues(alpha: 0.6),
                    ),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              )
            else
              const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _applyAndClose,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

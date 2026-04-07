import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchPage extends StatefulWidget {
  final Function(String)? onSearch;
  final String initialQuery;

  const SearchPage({
    super.key,
    this.onSearch,
    this.initialQuery = '',
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

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
          decoration: InputDecoration(
            hintText: 'Search events...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      if (widget.onSearch != null) {
                        widget.onSearch!('');
                      }
                      setState(() {});
                      Navigator.pop(context);
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() {}),
          onSubmitted: (value) {
            if (value.isNotEmpty && widget.onSearch != null) {
              widget.onSearch!(value);
              Navigator.pop(context);
            }
          },
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
      body: const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_list_item.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  final List<EventListItem> availableEvents;

  const SearchPage({
    super.key,
    this.initialQuery = '',
    this.availableEvents = const [],
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  void _applyAndClose() {
    Navigator.pop(context, _searchController.text.trim());
  }

  void _closeWithCurrentQuery() {
    Navigator.pop(context, _searchController.text.trim());
  }

  List<EventListItem> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.availableEvents;
    return widget.availableEvents.where((event) {
      final title = event.title.toLowerCase();
      final venue = event.venue.toLowerCase();
      final location = event.location.toLowerCase();
      return title.contains(query) || venue.contains(query) || location.contains(query);
    }).toList();
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
          onPressed: _closeWithCurrentQuery,
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
            onPressed: _closeWithCurrentQuery,
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
                  'Showing matching available events.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 13,
                  ),
                ),
              )
            else
              Text(
                'Available events',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withValues(alpha: 0.95),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredEvents.isEmpty
                  ? Center(
                      child: Text(
                        'No events match this query.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredEvents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(
                            Icons.event_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${event.venue} • ${event.location}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                            ),
                          ),
                          onTap: () {
                            _searchController.text = event.title;
                            _applyAndClose();
                          },
                        );
                      },
                    ),
            ),
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

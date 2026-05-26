import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../explore/presentation/pages/business_detail_page.dart';
import '../../domain/entities/business_presence.dart';
import '../widgets/owner_business_group_card.dart';
import '../widgets/owner_location_branch_card.dart';
import 'add_new_presence_page.dart';

/// Business locations selector: list of businesses/locations + Add New Presence.
class BusinessLocationsPage extends StatefulWidget {
  final List<BusinessPresence> presences;
  final String? currentPresenceId;
  /// When set, replaces the dynamic group/location title in the app bar (e.g. "My Businesses").
  final String? overrideAppBarTitle;
  /// When true with [overrideAppBarTitle], shows one card per listing (branch-style UI).
  final bool flatBranchCardLayout;

  const BusinessLocationsPage({
    super.key,
    this.presences = const <BusinessPresence>[],
    this.currentPresenceId,
    this.overrideAppBarTitle,
    this.flatBranchCardLayout = false,
  });

  @override
  State<BusinessLocationsPage> createState() => _BusinessLocationsPageState();
}

class _BusinessLocationsPageState extends State<BusinessLocationsPage> {
  late String? _selectedId;
  List<BusinessPresence> _presences = [];
  String? _groupName;

  @override
  void initState() {
    super.initState();
    _presences = List.from(widget.presences);
    final nonAll = _presences.where((p) => p.id != 'all').toList();
    _selectedId = widget.currentPresenceId ??
        (nonAll.isNotEmpty ? nonAll.first.id : null);
    BusinessPresence? selected;
    try {
      selected = _presences.firstWhere((p) => p.id == _selectedId);
    } catch (_) {
      selected = null;
    }
    _groupName = selected?.businessGroupName ?? selected?.name;
  }

  @override
  void didUpdateWidget(BusinessLocationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presences != widget.presences) {
      _presences = List.from(widget.presences);
    }
  }

  String get _selectedLocationName {
    if (_selectedId == null) return '';
    final match = _presences.where((p) => p.id == _selectedId);
    return match.isEmpty ? '' : (match.first.locationName ?? '');
  }

  bool get _isMyBusinessesLayout => widget.overrideAppBarTitle != null;

  @override
  Widget build(BuildContext context) {
    BusinessPresence? allPresence;
    try {
      allPresence = _presences.firstWhere((p) => p.id == 'all');
    } catch (_) {
      allPresence = null;
    }
    final rest = _presences.where((p) => p.id != 'all').toList();
    final byGroup = <String, List<BusinessPresence>>{};
    for (final p in rest) {
      final g = p.businessGroupName ?? p.name;
      byGroup.putIfAbsent(g, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isMyBusinessesLayout ? Icons.arrow_back : Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.overrideAppBarTitle != null
            ? Text(
                widget.overrideAppBarTitle!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _groupName ?? 'Businesses',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_selectedId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _selectedLocationName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
        centerTitle: true,
      ),
      body: _isMyBusinessesLayout
          ? (widget.flatBranchCardLayout
              ? _buildMyLocationsBranchCardsBody(rest)
              : _buildMyBusinessesBody(byGroup))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
              children: [
                if (allPresence != null)
                  _buildListItem(allPresence, 'Portfolio Overview', Icons.business_center),
                ...byGroup.entries.expand((e) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    ...e.value.map((p) => _buildLocationTile(p)),
                  ];
                }),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: _isMyBusinessesLayout
              ? OwnerAddNewBusinessCtaButton(
                  onPressed: () => _openAddNewPresence(context),
                  buttonLabel: widget.flatBranchCardLayout
                      ? 'Add New Location'
                      : 'Add New Business',
                  promptText: widget.flatBranchCardLayout
                      ? 'Have another branch?'
                      : null,
                )
              : AppButton(
                  text: 'Add New Presence',
                  onPressed: () => _openAddNewPresence(context),
                  icon: Icons.add,
                ),
        ),
      ),
    );
  }

  Widget _buildMyLocationsBranchCardsBody(List<BusinessPresence> rest) {
    if (rest.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            'No locations yet. Add one to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    final byId = {for (final p in rest) p.id: p};
    final byRoot = <String, List<BusinessPresence>>{};
    for (final p in rest) {
      final rootKey = p.parentBusinessId ?? p.id;
      byRoot.putIfAbsent(rootKey, () => []).add(p);
    }

    int compareWithinGroup(BusinessPresence a, BusinessPresence b, String rootId) {
      final aRoot = a.id == rootId;
      final bRoot = b.id == rootId;
      if (aRoot != bRoot) return aRoot ? -1 : 1;
      final na = (a.locationLabel?.trim().isNotEmpty ?? false)
          ? a.locationLabel!.trim()
          : a.name;
      final nb = (b.locationLabel?.trim().isNotEmpty ?? false)
          ? b.locationLabel!.trim()
          : b.name;
      return na.toLowerCase().compareTo(nb.toLowerCase());
    }

    final rootIds = byRoot.keys.toList()
      ..sort((a, b) {
        final titleA = byId[a]?.name ?? '';
        final titleB = byId[b]?.name ?? '';
        return titleA.toLowerCase().compareTo(titleB.toLowerCase());
      });

    final children = <Widget>[];
    for (var i = 0; i < rootIds.length; i++) {
      final rootId = rootIds[i];
      final members = List<BusinessPresence>.from(byRoot[rootId]!)
        ..sort((a, b) => compareWithinGroup(a, b, rootId));

      if (members.length > 1) {
        final headerTitle = byId[rootId]?.name ?? members.first.name;
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 4),
            child: Text(
              headerTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }

      for (var j = 0; j < members.length; j++) {
        children.add(
          OwnerLocationBranchCard(
            presence: members[j],
            onCardTap: () => _selectAndPop(members[j].id),
            onView: () => _openPublicBusinessListing(context, members[j].id),
          ),
        );
        if (j < members.length - 1) {
          children.add(const SizedBox(height: 14));
        }
      }
      if (i < rootIds.length - 1) {
        children.add(const SizedBox(height: 20));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        AppResources.spacingM,
        AppResources.spacingM,
        AppResources.spacingL,
      ),
      children: children,
    );
  }

  Widget _buildMyBusinessesBody(Map<String, List<BusinessPresence>> byGroup) {
    final entries = byGroup.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingL),
          child: Text(
            'No businesses yet. Add one to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        AppResources.spacingM,
        AppResources.spacingM,
        AppResources.spacingL,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppResources.spacingM),
      itemBuilder: (context, index) {
        final e = entries[index];
        return OwnerBusinessGroupCard(
          groupKey: e.key,
          locations: e.value,
          currentPresenceId: widget.currentPresenceId,
          onPresenceSelected: (id) => _selectAndPop(id),
        );
      },
    );
  }

  Widget _buildListItem(BusinessPresence p, String subtitle, IconData iconData) {
    return InkWell(
      onTap: () => _selectAndPop(p.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: AppColors.brandSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(BusinessPresence p) {
    final isSelected = p.id == _selectedId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedId = p.id;
          _groupName = p.businessGroupName ?? p.name;
        });
        _selectAndPop(p.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppColors.brandPrimary, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.locationName ?? p.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    p.statusDisplayText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.brandPrimary, size: 24),
          ],
        ),
      ),
    );
  }

  void _selectAndPop(String? id) {
    Navigator.pop(context, id);
  }

  void _openPublicBusinessListing(BuildContext context, String businessId) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BusinessDetailPage(businessId: businessId),
      ),
    );
  }

  Future<void> _openAddNewPresence(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNewPresencePage(presences: _presences),
      ),
    );
    if (!context.mounted) return;
    // Presences stay as-is; parent will have fresh data on next open
  }
}

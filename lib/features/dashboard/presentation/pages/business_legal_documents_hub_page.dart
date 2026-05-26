import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'business_legal_documents_detail_page.dart';

/// Lists businesses for the signed-in owner; each opens [BusinessLegalDocumentsDetailPage].
class BusinessLegalDocumentsHubPage extends StatefulWidget {
  const BusinessLegalDocumentsHubPage({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<BusinessLegalDocumentsHubPage> createState() =>
      _BusinessLegalDocumentsHubPageState();
}

class _BusinessLegalDocumentsHubPageState extends State<BusinessLegalDocumentsHubPage> {
  List<BusinessPresence>? _businesses;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await di.sl<DashboardRepository>().getOwnerBusinesses(widget.ownerId);
      if (!mounted) return;
      setState(() {
        _businesses = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal documents'),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundWhite,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final items = _businesses ?? [];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You don’t have any businesses yet. Add a business to upload compliance documents.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.backgroundGrey),
        itemBuilder: (context, index) {
          final b = items[index];
          final subtitle = b.locationName != null && b.locationName!.isNotEmpty
              ? b.locationName
              : null;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              b.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: subtitle != null
                ? Text(subtitle, style: TextStyle(color: AppColors.textSecondary))
                : null,
            trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => BusinessLegalDocumentsDetailPage(
                    businessId: b.id,
                    businessName: b.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

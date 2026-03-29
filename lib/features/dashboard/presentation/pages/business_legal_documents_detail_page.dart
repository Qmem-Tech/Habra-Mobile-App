import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/business_legal_document.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Compliance uploads for one business: status, dates, open file link.
class BusinessLegalDocumentsDetailPage extends StatefulWidget {
  const BusinessLegalDocumentsDetailPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessLegalDocumentsDetailPage> createState() =>
      _BusinessLegalDocumentsDetailPageState();
}

class _BusinessLegalDocumentsDetailPageState extends State<BusinessLegalDocumentsDetailPage> {
  List<BusinessLegalDocument>? _docs;
  LegalDocumentsStatus? _summary;
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
      final repo = di.sl<DashboardRepository>();
      final docs = await repo.listBusinessLegalDocuments(widget.businessId);
      final status = await repo.getLegalDocumentsStatus(widget.businessId);
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _summary = status;
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

  static String _typeLabel(String type) {
    switch (type) {
      case 'business_license':
        return 'Business license';
      case 'ein_proof':
        return 'EIN / tax ID proof';
      case 'doc_1':
        return 'Document 1';
      case 'doc_2':
        return 'Document 2';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  static String _statusLabel(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file link.')),
        );
      }
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessName),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundWhite,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_summary != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: _SummaryCard(status: _summary!),
                          ),
                        ),
                      ],
                      if ((_docs ?? []).isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No documents on file yet. Upload from the home screen when prompted, or from your business tools.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final d = _docs![index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Card(
                                  elevation: 0,
                                  color: AppColors.backgroundLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppColors.backgroundGrey),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _typeLabel(d.documentType),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(d.status)
                                                    .withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _statusLabel(d.status),
                                                style: TextStyle(
                                                  color: _statusColor(d.status),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (d.fileName != null &&
                                            d.fileName!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            d.fileName!,
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        if (d.uploadedAt != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Uploaded ${dateFmt.format(d.uploadedAt!.toLocal())}',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        if (d.reviewedAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Reviewed ${dateFmt.format(d.reviewedAt!.toLocal())}',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        if (d.rejectionReason != null &&
                                            d.rejectionReason!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Reason: ${d.rejectionReason}',
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          onPressed: () => _openUrl(context, d.fileUrl),
                                          icon: const Icon(Icons.open_in_new, size: 18),
                                          label: const Text('View file'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _docs!.length,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.status});

  final LegalDocumentsStatus status;

  @override
  Widget build(BuildContext context) {
    String line;
    if (status.isFullyApproved) {
      line = 'All submitted documents are approved.';
    } else if (status.awaitingLegalDocReview) {
      line = 'Documents are submitted and awaiting review.';
    } else if (status.hasRejected) {
      line = 'At least one document was rejected — upload a replacement where needed.';
      if (status.rejectionReasons.isNotEmpty) {
        line = '$line\n\nReviewer notes: ${status.rejectionReasons.join(' · ')}';
      }
    } else if (status.needsOwnerAction) {
      line = 'Required documents are missing. Complete upload from home or business tools.';
    } else {
      line = 'Compliance status is being determined.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.brandPrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
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

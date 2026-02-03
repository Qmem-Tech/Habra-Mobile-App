import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dev/dev_api_logger.dart';
import '../theme/app_colors.dart';

/// Dev-only overlay: floating button to open API request/response log.
/// Only shown when [kDebugMode] is true.
class DevApiOverlay extends StatefulWidget {
  const DevApiOverlay({super.key});

  @override
  State<DevApiOverlay> createState() => _DevApiOverlayState();
}

class _DevApiOverlayState extends State<DevApiOverlay> {
  @override
  void initState() {
    super.initState();
    DevApiLogger.instance.updateNotifier.addListener(_onUpdate);
  }

  @override
  void dispose() {
    DevApiLogger.instance.updateNotifier.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _openLogPopup(BuildContext context) {
    DevApiLogger.instance.enableRecording();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _DevApiLogPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Positioned(
      right: 12,
      bottom: 100,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        color: AppColors.brandPrimary.withValues(alpha: 0.9),
        child: InkWell(
          onTap: () => _openLogPopup(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'API',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (DevApiLogger.instance.entries.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${DevApiLogger.instance.entries.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Popup dialog for API log (avoids extra surface / BLASTBufferQueue issues).
class _DevApiLogPopup extends StatefulWidget {
  @override
  State<_DevApiLogPopup> createState() => _DevApiLogPopupState();
}

class _DevApiLogPopupState extends State<_DevApiLogPopup> {
  @override
  void initState() {
    super.initState();
    DevApiLogger.instance.updateNotifier.addListener(_onUpdate);
  }

  @override
  void dispose() {
    DevApiLogger.instance.updateNotifier.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = DevApiLogger.instance.entries;
    return Dialog(
      backgroundColor: AppColors.backgroundWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'API log (dev)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      if (entries.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            DevApiLogger.instance.clear();
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Clear'),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Recording on. Trigger an API call (e.g. Sign in, Sign up) and it will appear here.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _LogEntryCard(entry: entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({required this.entry});

  final ApiLogEntry entry;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.copyableText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: entry.isError ? AppColors.error : AppColors.backgroundGrey,
          width: entry.isError ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showEntryDetail(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.isError
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.method,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: entry.isError ? AppColors.error : AppColors.info,
                      ),
                    ),
                  ),
                  if (entry.responseStatus != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${entry.responseStatus}',
                      style: TextStyle(
                        fontSize: 10,
                        color: entry.responseStatus! >= 400
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(context),
                    tooltip: 'Copy request & response',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.path,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.responseData != null) ...[
                const SizedBox(height: 4),
                Text(
                  _preview(entry.responseData),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _preview(dynamic data) {
    if (data == null) return '';
    if (data is Map || data is List) {
      final s = data.toString();
      return s.length > 120 ? '${s.substring(0, 120)}...' : s;
    }
    final s = data.toString();
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }

  void _showEntryDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EntryDetailDialog(
        entry: entry,
        dialogContext: dialogContext,
      ),
    );
  }
}

class _EntryDetailDialog extends StatelessWidget {
  const _EntryDetailDialog({
    required this.entry,
    required this.dialogContext,
  });

  final ApiLogEntry entry;
  final BuildContext dialogContext;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.copyableText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${entry.method} ${entry.responseStatus ?? "—"}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copy(dialogContext),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                entry.path,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      title: 'Request',
                      body: _formatData(entry.requestData),
                      headers: entry.requestHeaders,
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Response',
                      body: _formatData(entry.responseData),
                      headers: entry.responseHeaders,
                      error: entry.errorMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatData(dynamic data) {
    if (data == null) return '—';
    if (data is Map || data is List) return data.toString();
    return data.toString();
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.headers,
    this.error,
  });

  final String title;
  final String body;
  final Map<String, dynamic>? headers;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        if (error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              error!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
                fontFamily: 'monospace',
              ),
            ),
          )
        else ...[
          if (headers != null && headers!.isNotEmpty)
            SelectableText(
              headers.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.textTertiary,
              ),
            ),
          if (headers != null && headers!.isNotEmpty) const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: SelectableText(
              body,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

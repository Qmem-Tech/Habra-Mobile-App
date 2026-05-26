import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../domain/entities/feedback_ticket.dart';
import '../bloc/admin_feedback_cubit.dart';
import '../bloc/admin_feedback_state.dart';

String _typeLabel(String type) {
  switch (type) {
    case 'positive':
      return 'Positive';
    case 'negative':
      return 'Negative';
    case 'bug_report':
      return 'Bug report';
    case 'suggestion':
      return 'Suggestion';
    default:
      return type;
  }
}

String _statusLabel(FeedbackTicketStatus s) {
  switch (s) {
    case FeedbackTicketStatus.open:
      return 'Open';
    case FeedbackTicketStatus.inProgress:
      return 'In progress';
    case FeedbackTicketStatus.resolved:
      return 'Resolved';
  }
}

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AdminFeedbackCubit>()..load(),
      child: const _AdminFeedbackView(),
    );
  }
}

class _AdminFeedbackView extends StatelessWidget {
  const _AdminFeedbackView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User feedback'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<AdminFeedbackCubit, AdminFeedbackState>(
        builder: (context, state) {
          if (state is AdminFeedbackLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminFeedbackError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<AdminFeedbackCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminFeedbackLoaded) {
            if (state.items.isEmpty) {
              return const Center(
                child: Text('No feedback submissions yet.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<AdminFeedbackCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _FeedbackListTile(
                    item: item,
                    onTap: () => _openDetailSheet(context, item),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openDetailSheet(BuildContext context, FeedbackTicket item) async {
    final cubit = context.read<AdminFeedbackCubit>();
    final notesController = TextEditingController(text: item.adminNotes ?? '');
    FeedbackTicketStatus status = item.status;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _typeLabel(item.type),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (item.submitterName != null &&
                        item.submitterName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'From: ${item.submitterName}'
                        '${item.submitterEmail != null && item.submitterEmail!.isNotEmpty ? ' · ${item.submitterEmail}' : ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Message',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.text),
                    const SizedBox(height: 20),
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<FeedbackTicketStatus>(
                      value: status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: FeedbackTicketStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => status = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin notes (internal)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Notes for your team…',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        final err = await cubit.updateTicket(
                          id: item.id,
                          status: status,
                          adminNotes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        );
                        if (!context.mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                          return;
                        }
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Feedback updated'),
                            ),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    notesController.dispose();
  }
}

class _FeedbackListTile extends StatelessWidget {
  final FeedbackTicket item;
  final VoidCallback onTap;

  const _FeedbackListTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _typeLabel(item.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(item.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal()),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

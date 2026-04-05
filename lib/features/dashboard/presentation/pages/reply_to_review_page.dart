import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../domain/entities/business_review.dart';
import '../bloc/dashboard_cubit.dart';

class ReplyToReviewPage extends StatefulWidget {
  const ReplyToReviewPage({
    super.key,
    required this.review,
    this.initialReplyText,
  });

  final BusinessReview review;
  /// Prefills the field when the owner edits an existing reply (same API as post).
  final String? initialReplyText;

  @override
  State<ReplyToReviewPage> createState() => _ReplyToReviewPageState();
}

class _ReplyToReviewPageState extends State<ReplyToReviewPage> {
  final _responseController = TextEditingController();
  static const int _maxChars = 500;

  bool get _isEditing {
    final s = widget.initialReplyText;
    return s != null && s.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReplyText;
    if (initial != null && initial.trim().isNotEmpty) {
      _responseController.text = initial.trim();
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _postResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a response')),
      );
      return;
    }
    final ctx = context;
    LoaderHelper.show(
      ctx,
      message: _isEditing ? 'Saving response...' : 'Posting response...',
    );
    String? postError;
    try {
      postError = await ctx.read<DashboardCubit>().replyToReview(
            widget.review.id,
            _responseController.text.trim(),
          );
    } finally {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
      }
    }
    if (!ctx.mounted) return;
    if (postError == null) {
      Navigator.pop(ctx, true);
    } else {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(postError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final initials = _replyPageAvatarInitials(r.authorName);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text(
          _isEditing ? 'Edit Response' : 'Reply to Review',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppResources.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Original Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            AppCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.backgroundGrey,
                  backgroundImage: r.authorImageUrl != null
                      ? NetworkImage(r.authorImageUrl!)
                      : null,
                  child: r.authorImageUrl == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: initials.length > 1 ? 11 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.authorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Row(children: [
                    ...List.generate(5, (i) {
                      final filled = i < r.rating;
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 16,
                        color: filled
                            ? AppColors.brandPrimary
                            : AppColors.textTertiary,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(r.timeAgo, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 12),
              Text(r.text, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _responseController,
              maxLines: 5,
              maxLength: _maxChars,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Write your response...',
                filled: true,
                fillColor: AppColors.backgroundWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppResources.radiusM), borderSide: BorderSide(color: AppColors.backgroundGrey)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            Align(alignment: Alignment.centerRight, child: Text('${_responseController.text.length}/$_maxChars characters', style: TextStyle(fontSize: 12, color: AppColors.textTertiary))),
            const SizedBox(height: 24),
            AppCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.brandPrimary, size: 22), const SizedBox(width: 8), const Text('Tips for a great response', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]),
              const SizedBox(height: 12),
              _TipBullet('Address the customer by name to make it personal.'),
              _TipBullet('Thank them for the specific feedback'),
              _TipBullet('Keep it professional, polite, and brief.'),
            ])),
            const SizedBox(height: 32),
            AppButton(
              text: _isEditing ? 'Save Response' : 'Post Response',
              onPressed: _postResponse,
            ),
          ],
        ),
      ),
    );
  }
}

String _replyPageAvatarInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final w = parts[0];
  if (w.length >= 2) return w.substring(0, 2).toUpperCase();
  return w[0].toUpperCase();
}

class _TipBullet extends StatelessWidget {
  const _TipBullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4))),
      ]),
    );
  }
}

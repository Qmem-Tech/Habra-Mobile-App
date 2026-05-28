import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';

class LegalHtmlPage extends StatefulWidget {
  const LegalHtmlPage({
    super.key,
    required this.slug,
    required this.fallbackTitle,
  });

  final String slug;
  final String fallbackTitle;

  @override
  State<LegalHtmlPage> createState() => _LegalHtmlPageState();
}

class _LegalHtmlPageState extends State<LegalHtmlPage> {
  late final Future<({String title, String html, String? updatedAt})> _future =
      _loadContent();

  Future<({String title, String html, String? updatedAt})> _loadContent() async {
    final row = await Supabase.instance.client
        .from('legal_content_pages')
        .select('title, html_content, updated_at')
        .eq('slug', widget.slug)
        .maybeSingle();

    if (row == null) {
      throw StateError('No legal content found for slug: ${widget.slug}');
    }

    final map = Map<String, dynamic>.from(row);
    final title = (map['title'] as String?)?.trim();
    final html = (map['html_content'] as String?)?.trim();
    final updatedAt = (map['updated_at'] as String?)?.trim();

    if (title == null || title.isEmpty || html == null || html.isEmpty) {
      throw StateError('Legal content is empty for slug: ${widget.slug}');
    }

    return (title: title, html: html, updatedAt: updatedAt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String title, String html, String? updatedAt})>(
      future: _future,
      builder: (context, snapshot) {
        final hasData = snapshot.hasData;
        final title = hasData ? snapshot.data!.title : widget.fallbackTitle;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: AppColors.backgroundWhite,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? _LegalErrorView(fallbackTitle: widget.fallbackTitle)
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppResources.spacingL,
                        vertical: AppResources.spacingM,
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppResources.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius:
                                BorderRadius.circular(AppResources.radiusL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Html(
                            data: snapshot.data!.html,
                            style: {
                              'body': Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                color: AppColors.textSecondary,
                                fontSize: FontSize(16),
                                lineHeight: const LineHeight(1.5),
                              ),
                              'h1': Style(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                margin: Margins.only(bottom: 12),
                              ),
                              'h2': Style(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                margin: Margins.only(top: 16, bottom: 8),
                              ),
                              'h3': Style(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                margin: Margins.only(top: 14, bottom: 8),
                              ),
                              'p': Style(
                                margin: Margins.only(bottom: 12),
                              ),
                              'ul': Style(margin: Margins.only(bottom: 12)),
                              'li': Style(
                                margin: Margins.only(bottom: 6),
                              ),
                              'a': Style(
                                color: AppColors.brandSecondary,
                                textDecoration: TextDecoration.underline,
                              ),
                            },
                          ),
                        ),
                        if (snapshot.data!.updatedAt != null &&
                            snapshot.data!.updatedAt!.isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingM),
                          Text(
                            'Last updated: ${snapshot.data!.updatedAt}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}

class _LegalErrorView extends StatelessWidget {
  const _LegalErrorView({required this.fallbackTitle});

  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              color: AppColors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: AppResources.spacingM),
            Text(
              '$fallbackTitle is currently unavailable.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppResources.spacingS),
            Text(
              'Please try again in a moment.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

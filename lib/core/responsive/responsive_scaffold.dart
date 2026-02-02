import 'package:flutter/material.dart';
import 'app_scroll_view.dart';

/// Scaffold that optionally wraps [body] in [AppScrollView] to prevent overflow.
///
/// Set [scrollable] to true for form-like pages. The body is then scrollable
/// and keyboard-aware, avoiding overflow on small screens.
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool scrollable;
  final EdgeInsetsGeometry? bodyPadding;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.scrollable = false,
    this.bodyPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body ?? const SizedBox.shrink();

    if (scrollable && body != null) {
      content = AppScrollView(
        padding: bodyPadding ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}

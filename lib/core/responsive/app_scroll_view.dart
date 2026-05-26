import 'package:flutter/material.dart';
import '../resources/app_resources.dart';

/// Scrollable body wrapper that prevents overflow across devices.
///
/// Use instead of raw [SingleChildScrollView] for forms, settings, and
/// any page with variable-height content. Handles keyboard and safe area.
///
/// Example:
/// ```dart
/// body: AppScrollView(
///   padding: EdgeInsets.all(AppResources.spacingM),
///   child: Column(children: [...]),
/// )
/// ```
class AppScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool primary;
  final bool useSafeArea;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const AppScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.primary = true,
    this.useSafeArea = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      primary: primary,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      keyboardDismissBehavior: keyboardDismissBehavior,
      child: child,
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

import 'package:flutter/material.dart';

/// Central responsive utilities.
///
/// Use [BuildContext] extensions for screen size, safe area, and scaled values.
/// Prefer [ScreenUtils.wp], [ScreenUtils.hp], and [ScreenUtils.sp] for
/// responsive layout to avoid overflow on small devices.
class ScreenUtils {
  ScreenUtils._();

  /// Breakpoints (logical pixels).
  static const double breakpointPhone = 600;
  static const double breakpointTablet = 900;
  static const double designWidth = 375;
  static const double designHeight = 812;

  /// Width as percentage of screen (0–1).
  static double wp(BuildContext context, double fraction) {
    return MediaQuery.sizeOf(context).width * fraction.clamp(0.0, 1.0);
  }

  /// Height as percentage of screen (0–1).
  static double hp(BuildContext context, double fraction) {
    return MediaQuery.sizeOf(context).height * fraction.clamp(0.0, 1.0);
  }

  /// Scale a value by width relative to [designWidth].
  static double sw(BuildContext context, double value) {
    final w = MediaQuery.sizeOf(context).width;
    return value * (w / designWidth);
  }

  /// Scale a value by height relative to [designHeight].
  static double sh(BuildContext context, double value) {
    final h = MediaQuery.sizeOf(context).height;
    return value * (h / designHeight);
  }

  /// Font size scaled by width (good for responsive text).
  static double sp(BuildContext context, double size) {
    return sw(context, size);
  }

  static bool _isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 600;
  }

  static bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= breakpointTablet;
  }

  static ScreenSize _screenSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= breakpointTablet) return ScreenSize.large;
    if (w >= breakpointPhone) return ScreenSize.medium;
    return ScreenSize.small;
  }
}

enum ScreenSize { small, medium, large }

extension ScreenUtilsExtension on BuildContext {
  MediaQueryData get _mq => MediaQuery.of(this);
  Size get _size => _mq.size;

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  double get safePaddingTop => _mq.padding.top;
  double get safePaddingBottom => _mq.padding.bottom;
  double get safePaddingLeft => _mq.padding.left;
  double get safePaddingRight => _mq.padding.right;

  /// Usable height below app bar / status bar.
  double get usableHeight => screenHeight - safePaddingTop - safePaddingBottom;

  bool get isSmallPhone => ScreenUtils._isSmallPhone(this);
  bool get isTablet => ScreenUtils._isTablet(this);
  ScreenSize get screenSize => ScreenUtils._screenSize(this);

  double wp(double fraction) => ScreenUtils.wp(this, fraction);
  double hp(double fraction) => ScreenUtils.hp(this, fraction);
  double sw(double value) => ScreenUtils.sw(this, value);
  double sh(double value) => ScreenUtils.sh(this, value);
  double sp(double size) => ScreenUtils.sp(this, size);
}

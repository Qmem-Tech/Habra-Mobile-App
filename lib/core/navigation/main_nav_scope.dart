import 'package:flutter/material.dart';

/// Provides access to the main navigation scaffold (for opening the drawer)
/// and optional user info for notification/location from any tab in the wrapper.
class MainNavScope extends InheritedWidget {
  const MainNavScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
    this.userId,
    this.userName,
    this.userEmail,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? userId;
  final String? userName;
  final String? userEmail;

  static MainNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavScope>();
  }

  static MainNavScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'MainNavScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(MainNavScope oldWidget) {
    return scaffoldKey != oldWidget.scaffoldKey ||
        userId != oldWidget.userId ||
        userName != oldWidget.userName ||
        userEmail != oldWidget.userEmail;
  }
}

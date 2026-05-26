import 'package:flutter/material.dart';

import '../../injection/injection_container.dart' as di;
import '../navigation/main_navigation_wrapper.dart';
import '../services/app_version_service.dart';
import 'force_update_dialog.dart';

/// Checks minimum app version on cold start and when returning from background.
class ForceUpdateHost extends StatefulWidget {
  const ForceUpdateHost({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateHost> createState() => _ForceUpdateHostState();
}

class _ForceUpdateHostState extends State<ForceUpdateHost>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking || _dialogVisible || isForceUpdateDialogVisible || !mounted) {
      return;
    }
    _checking = true;
    try {
      final status = await di.sl<AppVersionService>().evaluate();
      if (!status.mustUpdate || !mounted) return;

      final navContext = mainNavigatorKey.currentContext ?? context;
      if (!navContext.mounted) return;

      _dialogVisible = true;
      await showForceUpdateDialog(navContext, status);
    } catch (_) {
      // Never block the app on remote config failures.
    } finally {
      _dialogVisible = false;
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

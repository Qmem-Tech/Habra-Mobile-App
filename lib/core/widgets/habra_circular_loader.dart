import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../resources/app_assets.dart';

/// Circular loader with rotating app icon
///
/// Use this for both inline and full-screen loading states
/// - For inline: Use default size or specify custom size
/// - For full-screen: Set fullScreen to true and optionally provide a message
class HabraCircularLoader extends StatefulWidget {
  final double? size;
  final Color? color;
  final bool fullScreen;
  final String? message;
  final Color? backgroundColor;

  const HabraCircularLoader({
    super.key,
    this.size,
    this.color,
    this.fullScreen = false,
    this.message,
    this.backgroundColor,
  });

  @override
  State<HabraCircularLoader> createState() => _HabraCircularLoaderState();
}

class _HabraCircularLoaderState extends State<HabraCircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? (widget.fullScreen ? 80.0 : 60.0);
    final color = widget.color ?? AppColors.brandPrimary;

    final loader = SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: widget.fullScreen ? 12 : 4,
                    offset: Offset(0, widget.fullScreen ? 4 : 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(size * 0.1),
              child: Image.asset(
                AppAssets.appLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a simple icon if logo not found
                  return Icon(
                    Icons.refresh,
                    size: size * 0.8,
                    color: color,
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    if (widget.fullScreen) {
      return Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: Container(
            color: widget.backgroundColor ?? Colors.transparent,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                loader,
                if (widget.message != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.message!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return loader;
  }
}

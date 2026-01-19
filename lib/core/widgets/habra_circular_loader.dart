import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../resources/app_assets.dart';

/// Circular loader with rotating app icon
///
/// Use this for inline loading states (similar to CircularProgressIndicator)
class HabraCircularLoader extends StatefulWidget {
  final double? size;
  final Color? color;

  const HabraCircularLoader({
    super.key,
    this.size,
    this.color,
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
    final size = widget.size ?? 24.0;
    final color = widget.color ?? AppColors.brandPrimary;

    return SizedBox(
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
  }
}

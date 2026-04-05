import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Business logos from Supabase are URLs; [Image.asset] fails for those.
class JobCompanyLogo extends StatelessWidget {
  const JobCompanyLogo({
    super.key,
    required this.url,
    required this.size,
    this.borderRadius = 8,
  });

  final String? url;
  final double size;
  final double borderRadius;

  bool get _isNetwork {
    final u = url?.trim() ?? '';
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final u = url?.trim() ?? '';
    Widget child;
    if (u.isEmpty) {
      child = _fallback();
    } else if (_isNetwork) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          u,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          u,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: u.isEmpty ? _fallback() : child,
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        Icons.business_rounded,
        size: size * 0.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Deal / business images from Supabase are HTTPS URLs; [Image.asset] breaks for those.
class DealNetworkImage extends StatelessWidget {
  const DealNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  bool get _isNetwork {
    final u = imageUrl.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final u = imageUrl.trim();
    Widget image;
    if (u.isEmpty) {
      image = _placeholder();
    } else if (_isNetwork) {
      image = Image.network(
        u,
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      image = Image.asset(
        u,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.backgroundGrey,
      alignment: Alignment.center,
      child: Icon(
        Icons.local_offer,
        size: (height != null && height! < 100) ? 32 : 56,
        color: AppColors.textSecondary,
      ),
    );
  }
}

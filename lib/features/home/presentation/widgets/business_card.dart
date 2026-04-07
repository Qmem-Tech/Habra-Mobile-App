import 'package:flutter/material.dart';
import '../../domain/entities/business.dart';
import '../../../../core/theme/app_colors.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback? onTap;

  const BusinessCard({
    super.key,
    required this.business,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLine = _categoryDistanceLine();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.backgroundGrey.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumb(),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name.trim().isEmpty
                              ? 'Business'
                              : business.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.customerHomePrimary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    categoryLine,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (business.status != null && business.status!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      business.status!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.customerHomePrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      business.rating.isFinite
                          ? business.rating.toStringAsFixed(1)
                          : '—',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (business.reviewCount > 0) ...[
                    const SizedBox(height: 1),
                  Text(
                    '(${business.reviewCount})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryDistanceLine() {
    final cat = business.category.trim();
    final dist = _formatDistance(business.distance);
    if (cat.isEmpty) return dist;
    return '$cat • $dist';
  }

  String _formatDistance(double distance) {
    if (!distance.isFinite || distance < 0) return '—';
    if (distance < 10) {
      final rounded = (distance * 10).round() / 10;
      return '${rounded == rounded.roundToDouble() ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1)} mi';
    }
    return '${distance.toStringAsFixed(1)} mi';
  }

  Widget _buildThumb() {
    final url = business.imageUrl.trim();
    if (url.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: AppColors.backgroundLight,
        child: const Icon(Icons.storefront, size: 30, color: AppColors.textSecondary),
      );
    }
    return Image.network(
      url,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: 50,
          height: 50,
          color: AppColors.backgroundLight,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 50,
          color: AppColors.backgroundGrey,
          child: const Icon(Icons.business, size: 32, color: AppColors.textSecondary),
        );
      },
    );
  }
}

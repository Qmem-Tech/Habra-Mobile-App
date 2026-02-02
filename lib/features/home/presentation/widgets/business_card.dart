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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundGrey.withValues(alpha:0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                business.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.business, size: 32, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.isVerified)
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${business.category} • ${_formatDistance(business.distance)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (business.status != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      business.status!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.brandPrimary,
                      ),
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
                      Icons.star,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      business.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '(${business.reviewCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1.0) {
      return '${(distance * 10).round() / 10} mi';
    }
    return '${distance.toStringAsFixed(1)} mi';
  }
}

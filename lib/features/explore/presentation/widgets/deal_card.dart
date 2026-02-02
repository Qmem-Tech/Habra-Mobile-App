import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/deal.dart';

class DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;

  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = deal.expiresAt != null &&
        deal.expiresAt!.difference(DateTime.now()).inDays <= 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.asset(
                    deal.imageUrl,
                    width: double.infinity,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 120,
                        color: AppColors.backgroundGrey,
                        child: const Icon(Icons.local_offer, size: 48, color: AppColors.textSecondary),
                      );
                    },
                  ),
                  if (isExpiringSoon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Expires Soon',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deal.business.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal.discountText ?? deal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deal.expiresAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isExpiringSoon ? Colors.red : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Expires ${_getExpiryText(deal.expiresAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpiringSoon ? Colors.red : AppColors.textSecondary,
                              fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExpiryText(DateTime expiresAt) {
    final difference = expiresAt.difference(DateTime.now());
    if (difference.inDays > 0) {
      return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'today';
    }
  }
}

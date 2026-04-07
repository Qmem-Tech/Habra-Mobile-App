import 'package:flutter/material.dart';
import '../../domain/entities/deal.dart';
import '../../../../core/theme/app_colors.dart';

class DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.deal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discountLabel = deal.discountPercent <= 0
        ? 'DEAL'
        : '${deal.discountPercent.toStringAsFixed(0)}% OFF';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 198,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.backgroundGrey.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.customerDealBadgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discountLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.customerHomePrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    deal.title.trim().isEmpty ? 'Special offer' : deal.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    deal.description.trim().isEmpty
                        ? 'Tap to view details'
                        : deal.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb() {
    final url = deal.imageUrl.trim();
    if (url.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        color: AppColors.customerDealBadgeBg,
        child: const Icon(Icons.local_offer, size: 32, color: AppColors.customerHomePrimary),
      );
    }
    return Image.network(
      url,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: 52,
          height: 52,
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
          width: 52,
          height: 52,
          color: AppColors.backgroundGrey,
          child: const Icon(Icons.local_offer, size: 32, color: AppColors.textSecondary),
        );
      },
    );
  }
}

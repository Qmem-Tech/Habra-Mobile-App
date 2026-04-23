import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../saved_items/domain/entities/saved_item.dart';
import '../../../saved_items/domain/usecases/save_item_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../../../core/theme/app_colors.dart';

/// Vertical, image-first deal card (customer home / mock).
class DealCard extends StatefulWidget {
  final Deal deal;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.deal,
    this.onTap,
  });

  static const double cardWidth = 170;
  static const double imageHeight = 132;

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  bool _savedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final discountLabel = deal.discountPercent <= 0
        ? 'DEAL'
        : '${deal.discountPercent.toStringAsFixed(0)}% OFF';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: DealCard.cardWidth,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: DealCard.imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        discountLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          _savedThisSession ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: _savedThisSession
                              ? const Color(0xFFE53935)
                              : AppColors.textSecondary,
                        ),
                        onPressed: () => _onHeartTap(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BusinessLogo(logoUrl: deal.businessLogoUrl, fallback: deal.imageUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (deal.businessName.trim().isNotEmpty)
                          Text(
                            deal.businessName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (deal.businessName.trim().isNotEmpty) const SizedBox(height: 2),
                        Text(
                          deal.title.trim().isEmpty ? 'Special offer' : deal.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _endsLabel(deal),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _endsLabel(Deal d) {
    final exp = d.expiryDate;
    if (exp == null) return 'Limited time';
    final now = DateTime.now();
    if (exp.isBefore(now)) return 'Expired';
    if (_isSameDay(exp, now)) return 'Ends today';
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    if (_isSameDay(exp, tomorrow)) return 'Ends tomorrow';
    return 'Ends ${exp.month}/${exp.day}/${exp.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _onHeartTap(BuildContext context) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save deals')),
      );
      return;
    }
    final d = widget.deal;
    final result = await di.sl<SaveItemUseCase>()(
      itemType: SavedItemType.deal,
      referenceId: d.id,
      title: d.title,
      subtitle: d.businessName,
      imageUrl: d.imageUrl.trim().isNotEmpty ? d.imageUrl : null,
    );
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        setState(() => _savedThisSession = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal saved to your list')),
        );
      },
    );
  }

  Widget _buildHeroImage() {
    final url = widget.deal.imageUrl.trim();
    if (url.isEmpty) {
      return Container(
        color: AppColors.customerDealBadgeBg,
        child: const Icon(Icons.local_offer, size: 48, color: AppColors.customerHomePrimary),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: DealCard.imageHeight,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.backgroundLight,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.customerDealBadgeBg,
        child: const Icon(Icons.local_offer, size: 48, color: AppColors.customerHomePrimary),
      ),
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  const _BusinessLogo({required this.logoUrl, required this.fallback});

  final String? logoUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final u = (logoUrl != null && logoUrl!.trim().isNotEmpty) ? logoUrl!.trim() : fallback.trim();
    if (u.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundLight,
        ),
        child: const Icon(Icons.storefront, size: 20, color: AppColors.textSecondary),
      );
    }
    return ClipOval(
      child: Image.network(
        u,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, e, s) => Container(
          width: 36,
          height: 36,
          color: AppColors.backgroundLight,
          child: const Icon(Icons.storefront, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

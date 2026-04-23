import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../saved_items/domain/entities/saved_item.dart';
import '../../../saved_items/domain/usecases/save_item_usecase.dart';
import '../../domain/entities/business.dart';
import '../../../../core/theme/app_colors.dart';

/// Image-first horizontal card for home: Call, Directions, Save (mock).
class FeaturedBusinessCard extends StatefulWidget {
  const FeaturedBusinessCard({
    super.key,
    required this.business,
    this.onOpenDetail,
  });

  final Business business;
  final VoidCallback? onOpenDetail;

  static const double cardWidth = 276;
  static const double imageHeight = 132;

  @override
  State<FeaturedBusinessCard> createState() => _FeaturedBusinessCardState();
}

class _FeaturedBusinessCardState extends State<FeaturedBusinessCard> {
  bool _savedThisSession = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final hero = (b.coverImageUrl != null && b.coverImageUrl!.trim().isNotEmpty)
        ? b.coverImageUrl!.trim()
        : b.imageUrl.trim();
    final logo = (b.logoUrl != null && b.logoUrl!.trim().isNotEmpty)
        ? b.logoUrl!.trim()
        : b.imageUrl.trim();

    return Container(
      width: FeaturedBusinessCard.cardWidth,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: FeaturedBusinessCard.imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroImage(url: hero),
                    if (b.isVerified)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.customerHomePrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
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
                          onPressed: () {
                            _onSaveTap();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Logo(logoUrl: logo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name.trim().isEmpty ? 'Business' : b.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                b.rating.isFinite ? b.rating.toStringAsFixed(1) : '—',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (b.reviewCount > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '(${b.reviewCount})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Text(
                  _categoryDistanceLine(b),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onPressed: b.phoneNumber != null && b.phoneNumber!.trim().isNotEmpty
                            ? () => _launchTel(b.phoneNumber!.trim())
                            : null,
                      ),
                    ),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.directions_outlined,
                        label: 'Directions',
                        onPressed: b.latitude != null && b.longitude != null
                            ? () => _launchMaps(b.latitude!, b.longitude!)
                            : () => _maybeShowNoDirections(context),
                      ),
                    ),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.bookmark_add_outlined,
                        label: 'Save',
                        onPressed: _onSaveTap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryDistanceLine(Business business) {
    final cat = business.category.trim();
    final dist = _formatDistance(business.distance);
    if (cat.isEmpty) return dist;
    return '$cat · $dist';
  }

  String _formatDistance(double distance) {
    if (!distance.isFinite || distance < 0) return '—';
    if (distance < 10) {
      final rounded = (distance * 10).round() / 10;
      return '${rounded == rounded.roundToDouble() ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1)} mi';
    }
    return '${distance.toStringAsFixed(1)} mi';
  }

  void _maybeShowNoDirections(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions available after location loads')),
    );
  }

  Future<void> _launchTel(String phone) async {
    final raw = phone.trim();
    if (raw.isEmpty) return;
    final uri = Uri.parse('tel:${Uri.encodeComponent(raw)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onSaveTap() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save businesses')),
      );
      return;
    }
    final b = widget.business;
    final result = await di.sl<SaveItemUseCase>()(
      itemType: SavedItemType.business,
      referenceId: b.id,
      title: b.name,
      subtitle: b.category,
      imageUrl: b.imageUrl.trim().isNotEmpty ? b.imageUrl : null,
    );
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        setState(() => _savedThisSession = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business saved to your list')),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.backgroundLight,
        child: const Icon(Icons.storefront, size: 48, color: AppColors.textSecondary),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: FeaturedBusinessCard.imageHeight,
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
      errorBuilder: (c, e, s) => Container(
        color: AppColors.backgroundLight,
        child: const Icon(Icons.storefront, size: 48, color: AppColors.textSecondary),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundLight,
        ),
        child: const Icon(Icons.storefront, size: 22, color: AppColors.textSecondary),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            width: 40,
            height: 40,
            color: AppColors.backgroundLight,
            child: const Icon(Icons.storefront, size: 22, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed == null
              ? AppColors.textTertiary
              : AppColors.customerHomePrimary,
          side: BorderSide(
            color: (onPressed == null ? AppColors.textTertiary : AppColors.customerHomePrimary)
                .withValues(alpha: 0.35),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

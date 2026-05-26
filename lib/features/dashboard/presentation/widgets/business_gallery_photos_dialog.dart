import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/subscription/business_gallery_access.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/widgets/tier_locked_gallery_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../../../../injection/injection_container.dart' as di;

/// Lets owners add, remove, and reorder (by remove/re-add) extra business photos
/// stored in `businesses.image_urls`.
class BusinessGalleryPhotosDialog extends StatefulWidget {
  const BusinessGalleryPhotosDialog({
    super.key,
    required this.businessId,
    required this.businessName,
    this.initialImageUrls = const [],
    this.subscriptionTier = BusinessSubscriptionTier.basic,
    /// Full-screen page (back button, no modal dialog).
    this.embeddedAsPage = false,
  });

  final String businessId;
  final String businessName;
  final List<String> initialImageUrls;
  final BusinessSubscriptionTier subscriptionTier;
  final bool embeddedAsPage;

  @override
  State<BusinessGalleryPhotosDialog> createState() =>
      _BusinessGalleryPhotosDialogState();
}

class _BusinessGalleryPhotosDialogState extends State<BusinessGalleryPhotosDialog> {
  late List<String> _savedUrls;
  late List<String> _initialSnapshot;
  final List<File> _newFiles = [];

  int get _maxGallery =>
      BusinessGalleryAccess.activeLimit(widget.subscriptionTier);

  int get _lockedCount =>
      BusinessGalleryAccess.lockedCount(_savedUrls, widget.subscriptionTier);

  void _popNavigator([List<String>? result]) {
    if (widget.embeddedAsPage) {
      Navigator.of(context).pop(result);
    } else {
      Navigator.of(context, rootNavigator: true).pop(result);
    }
  }

  @override
  void initState() {
    super.initState();
    _initialSnapshot = List<String>.from(widget.initialImageUrls);
    _savedUrls = List<String>.from(widget.initialImageUrls);
  }

  int get _totalCount => _savedUrls.length + _newFiles.length;

  bool get _dirty =>
      !listEquals(_savedUrls, _initialSnapshot) || _newFiles.isNotEmpty;

  Future<void> _pickImage() async {
    if (_totalCount >= _maxGallery) {
      if (!mounted) return;
      final msg = _lockedCount > 0
          ? 'Remove locked photos first, or upgrade your plan to add more.'
          : 'You can have up to $_maxGallery photos on your current plan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _newFiles.add(file));
    }
  }

  void _removeSaved(int index) {
    setState(() => _savedUrls.removeAt(index));
  }

  void _removeNew(int index) {
    setState(() => _newFiles.removeAt(index));
  }

  Future<void> _save() async {
    if (!_dirty) {
      _popNavigator();
      return;
    }

    final ctx = context;
    for (final f in _newFiles) {
      final size = await f.length();
      if (!ctx.mounted) return;
      if (size > FileUtils.maxImageBytes) {
        ErrorDisplayHelper.show(
          ctx,
          message:
              '${f.path.split('/').last} is ${FileUtils.formatFileSize(size)}. Max 5 MB per file.',
          title: 'File too large',
        );
        return;
      }
    }
    if (!ctx.mounted) return;

    final cubit = ctx.read<DashboardCubit>();
    if (Supabase.instance.client.auth.currentUser == null) return;

    LoaderHelper.show(ctx, message: 'Saving...');

    try {
      List<String> merged = List<String>.from(_savedUrls);
      if (_newFiles.isNotEmpty) {
        final uploaded = await di.sl<StorageService>().uploadImages(
          SupabaseBuckets.businesses,
          '${widget.businessId}/gallery',
          _newFiles,
        );
        merged = [...merged, ...uploaded];
      }

      final success = await cubit.updateBusiness(widget.businessId, {
        'image_urls': merged,
      });

      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;

      if (success) {
        _popNavigator(merged);
      } else {
        final errorMsg = cubit.state is DashboardError
            ? (cubit.state as DashboardError).message
            : null;
        ErrorDisplayHelper.show(
          ctx,
          message: 'Couldn\'t save photos. Please try again.',
          title: 'Update failed',
          error: errorMsg != null ? Exception(errorMsg) : null,
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Upload failed');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = Text(
      '${widget.businessName} — up to $_maxGallery '
      'extra photos on your current plan (shown on your listing). Max 5 MB each.',
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );

    final gridSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_savedUrls.isEmpty && _newFiles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No extra photos yet. Tap + to add.',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppResources.radiusM),
                  border: Border.all(color: AppColors.backgroundGrey),
                ),
                child: Icon(Icons.add, color: AppColors.textTertiary),
              ),
            ),
            ...List.generate(_savedUrls.length, (i) {
              final url = _savedUrls[i];
              final locked = i >= _maxGallery;
              return _thumbTile(
                locked: locked,
                onRemove: () => _removeSaved(i),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: AppColors.backgroundGrey,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            }),
            ...List.generate(_newFiles.length, (i) {
              final file = _newFiles[i];
              final slot = _savedUrls.length + i;
              final locked = slot >= _maxGallery;
              return _thumbTile(
                locked: locked,
                onRemove: () => _removeNew(i),
                child: Image.file(file, fit: BoxFit.cover),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        buildGalleryPlanSummary(
          totalCount: _totalCount,
          activeLimit: _maxGallery,
          lockedCount: _lockedCount,
        ),
      ],
    );

    final actionRow = Padding(
      padding: const EdgeInsets.all(AppResources.spacingL),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _popNavigator(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: 'Save',
              onPressed: _dirty ? _save : null,
            ),
          ),
        ],
      ),
    );

    if (widget.embeddedAsPage) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: const Text(
            'Manage photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppResources.spacingL,
                0,
                AppResources.spacingL,
                AppResources.spacingS,
              ),
              child: description,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingL,
                ),
                child: gridSection,
              ),
            ),
            actionRow,
          ],
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppResources.spacingL,
                AppResources.spacingM,
                AppResources.spacingS,
                0,
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: AppColors.brandPrimary, size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Business photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _popNavigator(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppResources.spacingL,
              ),
              child: description,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingL,
                ),
                child: gridSection,
              ),
            ),
            actionRow,
          ],
        ),
      ),
    );
  }

  Widget _thumbTile({
    required Widget child,
    required bool locked,
    required VoidCallback onRemove,
  }) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TierLockedGalleryImage(
              locked: locked,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              child: child,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

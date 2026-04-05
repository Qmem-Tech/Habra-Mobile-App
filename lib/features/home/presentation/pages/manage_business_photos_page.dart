import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/business_media_limits.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../../domain/entities/business_presence.dart';

/// Full-screen editor for cover, logo, and gallery (`BusinessPresence` media).
String _fileBasename(String path) {
  final i = path.replaceAll(r'\', '/').lastIndexOf('/');
  return i >= 0 ? path.substring(i + 1) : path;
}

class ManageBusinessPhotosPage extends StatefulWidget {
  const ManageBusinessPhotosPage({super.key, required this.business});

  final BusinessPresence business;

  @override
  State<ManageBusinessPhotosPage> createState() =>
      _ManageBusinessPhotosPageState();
}

class _ManageBusinessPhotosPageState extends State<ManageBusinessPhotosPage> {
  static const int _galleryPageSize = 9;

  String? _initialLogoUrl;
  String? _initialBackgroundUrl;
  List<String> _initialGalleryUrls = [];

  File? _logoFile;
  File? _coverFile;
  String? _logoUrl;
  String? _backgroundUrl;

  List<String> _galleryUrls = [];
  final List<File> _newGalleryFiles = [];

  /// Shown gallery thumbnails (excluding the Add tile). "Load more" when total exceeds this.
  int _visibleGalleryThumbs = 0;

  @override
  void initState() {
    super.initState();
    _hydrateFromBusiness(widget.business);
  }

  void _hydrateFromBusiness(BusinessPresence b) {
    _initialLogoUrl = b.logoUrl;
    _initialBackgroundUrl = b.backgroundUrl;
    _initialGalleryUrls = List<String>.from(b.imageUrls);
    _logoUrl = b.logoUrl;
    _backgroundUrl = b.backgroundUrl;
    _galleryUrls = List<String>.from(b.imageUrls);
    _newGalleryFiles.clear();
    _logoFile = null;
    _coverFile = null;
    final total = _galleryUrls.length;
    _visibleGalleryThumbs = total <= _galleryPageSize
        ? total
        : _galleryPageSize;
  }

  int get _galleryTotal => _galleryUrls.length + _newGalleryFiles.length;

  bool get _dirty {
    if (_logoFile != null || _coverFile != null) return true;
    if (!listEquals(_galleryUrls, _initialGalleryUrls)) return true;
    if (_newGalleryFiles.isNotEmpty) return true;
    final logoSame = (_logoUrl ?? '') == (_initialLogoUrl ?? '');
    final bgSame = (_backgroundUrl ?? '') == (_initialBackgroundUrl ?? '');
    return !logoSame || !bgSame;
  }

  Future<void> _pickCover() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _coverFile = file);
    }
  }

  Future<void> _pickLogo() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _logoFile = file);
    }
  }

  Future<void> _pickGalleryImage() async {
    if (_galleryTotal >= BusinessMediaLimits.maxGalleryImages) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can have up to ${BusinessMediaLimits.maxGalleryImages} gallery photos.',
          ),
        ),
      );
      return;
    }
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() {
        _newGalleryFiles.add(file);
        if (_visibleGalleryThumbs < _galleryTotal) {
          _visibleGalleryThumbs = _galleryTotal;
        }
      });
    }
  }

  void _removeSavedGallery(int index) {
    setState(() {
      _galleryUrls.removeAt(index);
      if (_visibleGalleryThumbs > _galleryTotal) {
        _visibleGalleryThumbs = _galleryTotal;
      }
    });
  }

  void _removeNewGallery(int index) {
    setState(() {
      _newGalleryFiles.removeAt(index);
      if (_visibleGalleryThumbs > _galleryTotal) {
        _visibleGalleryThumbs = _galleryTotal;
      }
    });
  }

  Future<void> _save() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final ctx = context;
    final filesToCheck = <File?>[_logoFile, _coverFile, ..._newGalleryFiles];
    for (final f in filesToCheck) {
      if (f == null) continue;
      final size = await f.length();
      if (!ctx.mounted) return;
      if (size > FileUtils.maxImageBytes) {
        ErrorDisplayHelper.show(
          ctx,
          message:
              '${_fileBasename(f.path)} is ${FileUtils.formatFileSize(size)}. Max 5 MB per file.',
          title: 'File too large',
        );
        return;
      }
    }
    if (!ctx.mounted) return;

    if (Supabase.instance.client.auth.currentUser == null) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('You need to be signed in to save.')),
        );
      }
      return;
    }

    final cubit = ctx.read<DashboardCubit>();
    LoaderHelper.show(ctx, message: 'Saving...');

    try {
      String? logoUrl = _logoUrl;
      String? backgroundUrl = _backgroundUrl;

      if (_logoFile != null) {
        logoUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.business.id}/logo',
          _logoFile!,
        );
      }
      if (_coverFile != null) {
        backgroundUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.business.id}/background',
          _coverFile!,
        );
      }

      List<String> mergedGallery = List<String>.from(_galleryUrls);
      if (_newGalleryFiles.isNotEmpty) {
        final uploaded = await di.sl<StorageService>().uploadImages(
          SupabaseBuckets.businesses,
          '${widget.business.id}/gallery',
          _newGalleryFiles,
        );
        mergedGallery = [...mergedGallery, ...uploaded];
      }
      if (mergedGallery.length > BusinessMediaLimits.maxGalleryImages) {
        mergedGallery =
            mergedGallery.sublist(0, BusinessMediaLimits.maxGalleryImages);
      }

      final data = <String, dynamic>{
        'logo_url': logoUrl ?? _initialLogoUrl,
        'background_url': backgroundUrl ?? _initialBackgroundUrl,
        'image_urls': mergedGallery,
      };

      final success = await cubit.updateBusiness(widget.business.id, data);

      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;

      if (success) {
        setState(() {
          _initialLogoUrl = logoUrl ?? _initialLogoUrl;
          _initialBackgroundUrl = backgroundUrl ?? _initialBackgroundUrl;
          _initialGalleryUrls = List<String>.from(mergedGallery);
          _logoUrl = logoUrl ?? _logoUrl;
          _backgroundUrl = backgroundUrl ?? _backgroundUrl;
          _galleryUrls = mergedGallery;
          _newGalleryFiles.clear();
          _logoFile = null;
          _coverFile = null;
        });
        if (mounted) Navigator.of(context).pop<List<String>>(mergedGallery);
      } else {
        final errorMsg = cubit.state is DashboardError
            ? (cubit.state as DashboardError).message
            : null;
        ErrorDisplayHelper.show(
          ctx,
          message: 'Couldn\'t save. Please try again.',
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

  Future<void> _onBackPressed() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
          centerTitle: true,
          title: Text(
            'Photos & Media',
            style: AppFonts.mediumTitle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: _dirty ? _save : null,
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _dirty
                      ? AppColors.brandSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppResources.spacingM,
            AppResources.spacingS,
            AppResources.spacingM,
            AppResources.spacingXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CoverSection(
                file: _coverFile,
                url: _backgroundUrl,
                onChangeTap: _pickCover,
              ),
              const SizedBox(height: AppResources.spacingXL),
              _LogoSection(
                file: _logoFile,
                url: _logoUrl,
                onChangeTap: _pickLogo,
              ),
              const SizedBox(height: AppResources.spacingXL),
              Text(
                'Gallery ($_galleryTotal)',
                textAlign: TextAlign.left,
                style: AppFonts.mediumTitle(color: AppColors.textPrimary)
                    .copyWith(fontSize: 17),
              ),
              const SizedBox(height: AppResources.spacingM),
              _GalleryGrid(
                visibleThumbCount: _visibleGalleryThumbs,
                savedUrls: _galleryUrls,
                newFiles: _newGalleryFiles,
                onAddTap: _pickGalleryImage,
                onRemoveSaved: _removeSavedGallery,
                onRemoveNew: _removeNewGallery,
                atGalleryLimit:
                    _galleryTotal >= BusinessMediaLimits.maxGalleryImages,
              ),
              if (_visibleGalleryThumbs < _galleryTotal) ...[
                const SizedBox(height: AppResources.spacingM),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final next = _visibleGalleryThumbs + _galleryPageSize;
                        _visibleGalleryThumbs = next > _galleryTotal
                            ? _galleryTotal
                            : next;
                      });
                    },
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.brandPrimary,
                    ),
                    label: const Text(
                      'Load More',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({
    required this.file,
    required this.url,
    required this.onChangeTap,
  });

  final File? file;
  final String? url;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cover Photo',
          textAlign: TextAlign.center,
          style: AppFonts.mediumTitle(color: AppColors.textPrimary)
              .copyWith(fontSize: 17),
        ),
        const SizedBox(height: AppResources.spacingM),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onChangeTap,
            borderRadius: BorderRadius.circular(AppResources.radiusXL),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppResources.radiusXL),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _coverChild(),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppResources.spacingM),
        Text(
          'This is the main image shown at the top of your profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppResources.spacingS),
        Center(
          child: TextButton(
            onPressed: onChangeTap,
            child: Text(
              'Change cover photo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverChild() {
    if (file != null) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _coverPlaceholder(),
      );
    }
    final u = url;
    if (u != null && u.isNotEmpty) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.backgroundLight,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _coverPlaceholder(),
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return ColoredBox(
      color: AppColors.backgroundLight,
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.file,
    required this.url,
    required this.onChangeTap,
  });

  final File? file;
  final String? url;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onChangeTap,
            customBorder: const CircleBorder(),
            child: _avatar(),
          ),
        ),
        const SizedBox(width: AppResources.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Logo',
                style: AppFonts.mediumTitle(color: AppColors.textPrimary)
                    .copyWith(fontSize: 17),
              ),
              const SizedBox(height: AppResources.spacingXS),
              Text(
                'Your logo appears in search results and next to your reviews.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppResources.spacingS),
              GestureDetector(
                onTap: onChangeTap,
                child: Text(
                  'Change Logo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar() {
    const size = 88.0;
    if (file != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.backgroundLight,
        backgroundImage: FileImage(file!),
      );
    }
    final u = url;
    if (u != null && u.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            u,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(
                color: AppColors.backgroundLight,
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => ColoredBox(
              color: AppColors.backgroundLight,
              child: Icon(
                Icons.storefront_outlined,
                size: 36,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.backgroundLight,
      child: Icon(
        Icons.storefront_outlined,
        size: 36,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.visibleThumbCount,
    required this.savedUrls,
    required this.newFiles,
    required this.onAddTap,
    required this.onRemoveSaved,
    required this.onRemoveNew,
    required this.atGalleryLimit,
  });

  final int visibleThumbCount;
  final List<String> savedUrls;
  final List<File> newFiles;
  final VoidCallback onAddTap;
  final void Function(int index) onRemoveSaved;
  final void Function(int index) onRemoveNew;
  final bool atGalleryLimit;

  @override
  Widget build(BuildContext context) {
    final thumbs = <Widget>[];
    var budget = visibleThumbCount;
    for (var i = 0; i < savedUrls.length && budget > 0; i++, budget--) {
      final index = i;
      thumbs.add(
        _GalleryThumb(
          image: Image.network(
            savedUrls[i],
            fit: BoxFit.cover,
            loadingBuilder: (context, w, progress) {
              if (progress == null) return w;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
          onRemove: () => onRemoveSaved(index),
        ),
      );
    }
    for (var j = 0; j < newFiles.length && budget > 0; j++, budget--) {
      final index = j;
      thumbs.add(
        _GalleryThumb(
          image: Image.file(
            newFiles[j],
            fit: BoxFit.cover,
          ),
          onRemove: () => onRemoveNew(index),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppResources.spacingS,
      mainAxisSpacing: AppResources.spacingS,
      childAspectRatio: 1,
      children: [
        _AddGalleryTile(
          enabled: !atGalleryLimit,
          onTap: onAddTap,
        ),
        ...thumbs,
      ],
    );
  }
}

class _AddGalleryTile extends StatelessWidget {
  const _AddGalleryTile({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandPrimary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppResources.radiusM),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(
              color: enabled ? AppColors.brandPrimary : AppColors.backgroundGrey,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: enabled
                        ? AppColors.brandPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color:
                      enabled ? AppColors.brandPrimary : AppColors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add New',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      enabled ? AppColors.brandPrimary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({
    required this.image,
    required this.onRemove,
  });

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppResources.radiusM),
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

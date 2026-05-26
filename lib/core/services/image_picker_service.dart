import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../permissions/app_permission.dart';
import 'permission_service.dart';
import '../../injection/injection_container.dart' as di;

/// Service for picking images from camera or gallery.
/// On Android, shows Habra permission dialog before gallery/camera when needed.
/// On iOS, opens the system picker directly (avoids broken modal + permission timing).
class ImagePickerService {
  ImagePickerService();

  final ImagePicker _picker = ImagePicker();

  PermissionService get _permissionService => di.sl<PermissionService>();

  /// Pick from gallery. Returns null if cancelled.
  ///
  /// On iOS 14+, [image_picker] uses PHPicker, which does not require photo
  /// library permission. Asking [Permission.photos] first often breaks after our
  /// own bottom sheets: the OS permission UI may not appear and the flow looks
  /// stuck. So we open the picker directly on iOS.
  ///
  /// On Android we still show the Habra dialog and request media permission.
  Future<File?> pickFromGallery(BuildContext context) async {
    if (Platform.isIOS) {
      return _pickFromGalleryInternal();
    }
    final granted = await _permissionService.requestWithDialog(
      context,
      AppPermission.photos,
    );
    if (!granted) return null;
    return _pickFromGalleryInternal();
  }

  Future<File?> _pickFromGalleryInternal() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Pick from camera. Returns null if cancelled.
  ///
  /// On iOS, the same pattern as gallery: our Habra sheet + [Permission.camera]
  /// right after another modal often prevents the system UI from appearing.
  /// Opening the camera picker directly lets iOS show its own camera prompt.
  /// A short delay lets the source bottom sheet finish dismissing first.
  ///
  /// On Android we keep the Habra dialog and explicit permission request.
  Future<File?> pickFromCamera(BuildContext context) async {
    if (Platform.isIOS) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!context.mounted) return null;
      return _pickFromCameraInternal();
    }
    final granted = await _permissionService.requestWithDialog(
      context,
      AppPermission.camera,
    );
    if (!granted) return null;
    return _pickFromCameraInternal();
  }

  Future<File?> _pickFromCameraInternal() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Show bottom sheet to choose camera or gallery. Returns null if cancelled.
  Future<File?> pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return null;
    return source == ImageSource.gallery
        ? pickFromGallery(context)
        : pickFromCamera(context);
  }
}

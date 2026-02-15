import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../permissions/app_permission.dart';
import 'permission_service.dart';
import '../../injection/injection_container.dart' as di;

/// Service for picking images from camera or gallery.
/// Shows Habra permission dialog before requesting camera/photos.
class ImagePickerService {
  ImagePickerService();

  final ImagePicker _picker = ImagePicker();

  PermissionService get _permissionService => di.sl<PermissionService>();

  /// Pick from gallery. Returns null if cancelled.
  /// Shows permission dialog first if photos access not granted.
  Future<File?> pickFromGallery(BuildContext context) async {
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
  /// Shows permission dialog first if camera access not granted.
  Future<File?> pickFromCamera(BuildContext context) async {
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
  /// Shows Habra permission dialog before picking if needed.
  Future<File?> pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// App permissions with Habra-themed metadata.
enum AppPermission {
  location,
  camera,
  photos,
  contacts,
}

extension AppPermissionExtension on AppPermission {
  Permission get permission {
    switch (this) {
      case AppPermission.location:
        return Permission.locationWhenInUse;
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.photos:
        return Permission.photos;
      case AppPermission.contacts:
        return Permission.contacts;
    }
  }

  String get title {
    switch (this) {
      case AppPermission.location:
        return 'Location';
      case AppPermission.camera:
        return 'Camera';
      case AppPermission.photos:
        return 'Photos';
      case AppPermission.contacts:
        return 'Contacts';
    }
  }

  String get description {
    switch (this) {
      case AppPermission.location:
        return 'Show nearby businesses and help you get directions';
      case AppPermission.camera:
        return 'Take photos for reviews and business profiles';
      case AppPermission.photos:
        return 'Add photos from your library to reviews and listings';
      case AppPermission.contacts:
        return 'Easily invite friends and share with contacts';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPermission.location:
        return Icons.location_on_rounded;
      case AppPermission.camera:
        return Icons.camera_alt_rounded;
      case AppPermission.photos:
        return Icons.photo_library_rounded;
      case AppPermission.contacts:
        return Icons.contacts_rounded;
    }
  }

  /// Permissions required for core app features (location, camera, photos).
  static List<AppPermission> get corePermissions => [
        AppPermission.location,
        AppPermission.camera,
        AppPermission.photos,
      ];

  /// All permissions the app may request.
  static List<AppPermission> get all => AppPermission.values;
}

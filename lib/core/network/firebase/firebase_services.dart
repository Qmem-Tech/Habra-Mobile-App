import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseServices {
  // Auth - Using "habra" naming convention for Flutter-related getters
  FirebaseAuth get habraAuth => FirebaseAuth.instance;

  // Firestore - Using "habra" naming convention
  FirebaseFirestore get habraFirestore => FirebaseFirestore.instance;

  // Storage - Using "habra" naming convention
  FirebaseStorage get habraStorage => FirebaseStorage.instance;

  // Messaging - Using "habra" naming convention
  FirebaseMessaging get habraMessaging => FirebaseMessaging.instance;

  // Remote Config - Using "habra" naming convention
  FirebaseRemoteConfig get habraRemoteConfig => FirebaseRemoteConfig.instance;

  // Static getters for backward compatibility (deprecated - use instance methods)
  @Deprecated('Use habraAuth instead')
  static FirebaseAuth get auth => FirebaseAuth.instance;

  @Deprecated('Use habraFirestore instead')
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @Deprecated('Use habraStorage instead')
  static FirebaseStorage get storage => FirebaseStorage.instance;

  @Deprecated('Use habraMessaging instead')
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  @Deprecated('Use habraRemoteConfig instead')
  static FirebaseRemoteConfig get remoteConfig => FirebaseRemoteConfig.instance;

  // Initialize Remote Config
  Future<void> initializeHabraRemoteConfig() async {
    final remoteConfig = habraRemoteConfig;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.fetchAndActivate();
  }

  // Static method for backward compatibility (deprecated)
  @Deprecated('Use initializeHabraRemoteConfig instead')
  static Future<void> initializeRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.fetchAndActivate();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseServices {
  // Auth
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Firestore
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Storage
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Messaging
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  // Remote Config
  static FirebaseRemoteConfig get remoteConfig => FirebaseRemoteConfig.instance;

  // Initialize Remote Config
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

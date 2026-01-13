import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/firebase/firebase_services.dart';
import '../../domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginAsGuest();
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  );
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseServices firebaseServices;

  AuthRemoteDataSourceImpl(this.firebaseServices);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firebaseServices.habraFirestore.collection('users');

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential =
          await firebaseServices.habraAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw ServerException('Login failed');
      }

      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) {
        // Fallback: create a basic customer profile if missing.
        final data = {
          'uid': user.uid,
          'email': user.email ?? email,
          'name': user.displayName ?? '',
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _usersCollection.doc(user.uid).set(data);
        return UserModel.fromFirebase(
          uid: user.uid,
          email: data['email'] as String,
          name: data['name'] as String,
          roleString: data['role'] as String,
        );
      }

      final data = doc.data()!;
      return UserModel.fromFirebase(
        uid: user.uid,
        email: data['email'] as String? ?? user.email ?? email,
        name: data['name'] as String? ?? user.displayName ?? '',
        roleString: data['role'] as String? ?? 'customer',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> loginAsGuest() async {
    try {
      final userCredential = await firebaseServices.habraAuth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        throw ServerException('Guest login failed');
      }

      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final data = {
          'uid': user.uid,
          'email': '',
          'name': 'Guest',
          'role': 'guest',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await docRef.set(data);
        return UserModel.fromFirebase(
          uid: user.uid,
          email: '',
          name: 'Guest',
          roleString: 'guest',
        );
      }

      final data = doc.data()!;
      return UserModel.fromFirebase(
        uid: user.uid,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? 'Guest',
        roleString: data['role'] as String? ?? 'guest',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      final userCredential =
          await firebaseServices.habraAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw ServerException('Registration failed');
      }

      await user.updateDisplayName(name);

      final roleString = UserModel.roleToString(role);

      final data = {
        'uid': user.uid,
        'email': user.email ?? email,
        'name': name,
        'role': roleString,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(user.uid).set(data);

      return UserModel.fromFirebase(
        uid: user.uid,
        email: data['email'] as String,
        name: name,
        roleString: roleString,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseServices.habraAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

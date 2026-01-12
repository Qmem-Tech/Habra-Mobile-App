import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/firebase/firebase_services.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseServices firebaseServices;

  AuthRemoteDataSourceImpl(this.firebaseServices);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final userCredential = await firebaseServices.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
        );
      } else {
        throw ServerException('Login failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    try {
      final userCredential = await firebaseServices.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        final user = userCredential.user!;
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: name,
        );
      } else {
        throw ServerException('Registration failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseServices.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

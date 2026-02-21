import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;

  EditProfileCubit({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
  }) : super(EditProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(EditProfileLoading());

    final result = await getProfileUseCase(userId);
    result.fold(
      (failure) => emit(EditProfileError(failure.message)),
      (profile) => emit(EditProfileLoaded(profile)),
    );
  }

  Future<void> saveProfile(String userId, UserProfileUpdate update) async {
    emit(EditProfileSaving());

    final result = await updateProfileUseCase(userId, update);
    result.fold(
      (failure) => emit(EditProfileSaveError(failure.message)),
      (profile) => emit(EditProfileSaveSuccess(profile)),
    );
  }

  /// Upload photo and update profile with avatar URL. On success emits [EditProfileSaveSuccess].
  Future<void> uploadPhoto(String userId, File imageFile) async {
    emit(EditProfileSaving());

    final uploadResult = await uploadAvatarUseCase(userId, imageFile);
    await uploadResult.fold(
      (failure) async => emit(EditProfileSaveError(failure.message)),
      (avatarUrl) async {
        final updateResult = await updateProfileUseCase(
          userId,
          UserProfileUpdate(avatarUrl: avatarUrl),
        );
        updateResult.fold(
          (failure) => emit(EditProfileSaveError(failure.message)),
          (profile) => emit(EditProfileSaveSuccess(profile)),
        );
      },
    );
  }
}

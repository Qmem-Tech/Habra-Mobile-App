import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

abstract class EditProfileState extends Equatable {
  const EditProfileState();

  @override
  List<Object?> get props => [];
}

class EditProfileInitial extends EditProfileState {}

class EditProfileLoading extends EditProfileState {}

class EditProfileLoaded extends EditProfileState {
  final UserProfile profile;

  const EditProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class EditProfileError extends EditProfileState {
  final String message;

  const EditProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class EditProfileSaving extends EditProfileState {}

class EditProfileSaveSuccess extends EditProfileState {
  final UserProfile profile;

  const EditProfileSaveSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

class EditProfileSaveError extends EditProfileState {
  final String message;

  const EditProfileSaveError(this.message);

  @override
  List<Object?> get props => [message];
}

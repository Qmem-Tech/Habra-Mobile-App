import 'package:equatable/equatable.dart';
import '../../domain/entities/splash_status.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashLoaded extends SplashState {
  final SplashStatus status;

  const SplashLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class SplashError extends SplashState {
  final String message;

  const SplashError(this.message);

  @override
  List<Object?> get props => [message];
}

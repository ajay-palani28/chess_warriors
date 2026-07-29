import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class EmailVerifiedSuccess extends ForgotPasswordState {
  final Map<String, dynamic> data;

  const EmailVerifiedSuccess(this.data);

  @override
  List<Object> get props => [data];
}

class PasswordResetSuccess extends ForgotPasswordState {
  final String message;

  const PasswordResetSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String error;

  const ForgotPasswordFailure(this.error);

  @override
  List<Object> get props => [error];
}

import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object> get props => [];
}

class VerifyEmailSubmitted extends ForgotPasswordEvent {
  final String email;

  const VerifyEmailSubmitted(this.email);

  @override
  List<Object> get props => [email];
}

class ResetPasswordSubmitted extends ForgotPasswordEvent {
  final String email;
  final String a1;
  final String a2;
  final String a3;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordSubmitted({
    required this.email,
    required this.a1,
    required this.a2,
    required this.a3,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [email, a1, a2, a3, newPassword, confirmPassword];
}

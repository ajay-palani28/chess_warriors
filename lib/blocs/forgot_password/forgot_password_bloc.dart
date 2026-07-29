import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final UserService userService;

  ForgotPasswordBloc({required this.userService}) : super(ForgotPasswordInitial()) {
    on<VerifyEmailSubmitted>(_onVerifyEmailSubmitted);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }

  Future<void> _onVerifyEmailSubmitted(
    VerifyEmailSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      final result = await userService.verifyEmail(event.email);
      if (result['success']) {
        emit(EmailVerifiedSuccess(result['data']));
      } else {
        emit(ForgotPasswordFailure(result['message']));
      }
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      final result = await userService.resetPassword(
        email: event.email,
        a1: event.a1,
        a2: event.a2,
        a3: event.a3,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );
      if (result['success']) {
        emit(PasswordResetSuccess(result['message']));
      } else {
        emit(ForgotPasswordFailure(result['message']));
      }
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }
}

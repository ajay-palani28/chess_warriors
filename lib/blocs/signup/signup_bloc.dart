import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final UserService userService;

  SignupBloc({required this.userService}) : super(SignupInitial()) {
    on<SignupSubmitted>(_onSignupSubmitted);
  }

  Future<void> _onSignupSubmitted(
    SignupSubmitted event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoading());
    try {
      final result = await userService.signup(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        q1: event.q1,
        a1: event.a1,
        q2: event.q2,
        a2: event.a2,
        q3: event.q3,
        a3: event.a3,
      );

      if (result['success']) {
        emit(SignupSuccess());
      } else {
        emit(SignupFailure(result['message'] ?? 'Signup failed'));
      }
    } catch (e) {
      emit(SignupFailure(e.toString()));
    }
  }
}

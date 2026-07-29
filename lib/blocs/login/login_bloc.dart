import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserService userService;

  LoginBloc({required this.userService}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final result = await userService.login(
        event.email,
        event.password,
      );

      if (result['success']) {
        emit(LoginSuccess());
      } else {
        emit(LoginFailure(result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}

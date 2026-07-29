import 'package:equatable/equatable.dart';

abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object> get props => [];
}

class SignupSubmitted extends SignupEvent {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String q1;
  final String a1;
  final String q2;
  final String a2;
  final String q3;
  final String a3;

  const SignupSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.q1,
    required this.a1,
    required this.q2,
    required this.a2,
    required this.q3,
    required this.a3,
  });

  @override
  List<Object> get props => [fullName, email, phone, password, q1, a1, q2, a2, q3, a3];
}

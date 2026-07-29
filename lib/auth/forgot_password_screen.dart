import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/user_service.dart';
import '../blocs/forgot_password/forgot_password_bloc.dart';
import '../blocs/forgot_password/forgot_password_event.dart';
import '../blocs/forgot_password/forgot_password_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _a1Controller = TextEditingController();
  final _a2Controller = TextEditingController();
  final _a3Controller = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _verifiedEmail;
  String? _q1, _q2, _q3;

  @override
  void dispose() {
    _emailController.dispose();
    _a1Controller.dispose();
    _a2Controller.dispose();
    _a3Controller.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleVerifyEmail(BuildContext context) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    context.read<ForgotPasswordBloc>().add(VerifyEmailSubmitted(email));
  }

  void _handleResetPassword(BuildContext context) {
    final a1 = _a1Controller.text.trim();
    final a2 = _a2Controller.text.trim();
    final a3 = _a3Controller.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (a1.isEmpty || a2.isEmpty || a3.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (newPass.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    context.read<ForgotPasswordBloc>().add(ResetPasswordSubmitted(
          email: _verifiedEmail!,
          a1: a1,
          a2: a2,
          a3: a3,
          newPassword: newPass,
          confirmPassword: confirmPass,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(userService: UserService()),
      child: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is EmailVerifiedSuccess) {
            setState(() {
              _verifiedEmail = state.data['email'];
              _q1 = state.data['securityQuestion1'];
              _q2 = state.data['securityQuestion2'];
              _q3 = state.data['securityQuestion3'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email verified. Answer security questions.')),
            );
          } else if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context); // Go back to login
          } else if (state is ForgotPasswordFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown[900]!,
                  Colors.brown[700]!,
                  Colors.brown[400]!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Icon(Icons.lock_reset, size: 70, color: Colors.white),
                    const SizedBox(height: 15),
                    Text(
                      _verifiedEmail == null ? 'Forgot Password' : 'Reset Password',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _verifiedEmail == null 
                          ? 'Enter your email to verify your account' 
                          : 'Answer your security questions to reset password',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    
                    if (_verifiedEmail == null) ...[
                      _buildTextField(_emailController, 'Email', Icons.email, false),
                      const SizedBox(height: 30),
                      _buildSubmitButton(context, 'VERIFY EMAIL'),
                    ] else ...[
                      _buildQuestionLabel(_q1 ?? 'Question 1'),
                      const SizedBox(height: 8),
                      _buildTextField(_a1Controller, 'Answer 1', Icons.question_answer, false),
                      
                      const SizedBox(height: 20),
                      _buildQuestionLabel(_q2 ?? 'Question 2'),
                      const SizedBox(height: 8),
                      _buildTextField(_a2Controller, 'Answer 2', Icons.question_answer, false),
                      
                      const SizedBox(height: 20),
                      _buildQuestionLabel(_q3 ?? 'Question 3'),
                      const SizedBox(height: 8),
                      _buildTextField(_a3Controller, 'Answer 3', Icons.question_answer, false),
                      
                      const SizedBox(height: 30),
                      _buildTextField(_newPasswordController, 'New Password', Icons.lock_outline, true),
                      const SizedBox(height: 15),
                      _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock, true),
                      
                      const SizedBox(height: 40),
                      _buildSubmitButton(context, 'RESET PASSWORD'),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionLabel(String question) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        question,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, String label) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: state is ForgotPasswordLoading 
                ? null 
                : () => _verifiedEmail == null 
                    ? _handleVerifyEmail(context) 
                    : _handleResetPassword(context),
            child: state is ForgotPasswordLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

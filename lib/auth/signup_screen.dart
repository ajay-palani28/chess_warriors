import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../main_navigation.dart';
import '../services/user_service.dart';
import '../blocs/signup/signup_bloc.dart';
import '../blocs/signup/signup_event.dart';
import '../blocs/signup/signup_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _q2Controller = TextEditingController();
  final _a1Controller = TextEditingController();
  final _a2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  final _a3Controller = TextEditingController();

  final List<String> _q1Options = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What was the name of your first school?",
    "What city were you born in?",
    "What is your favorite chess opening?",
  ];
  String? _selectedQ1;

  @override
  void initState() {
    super.initState();
    _selectedQ1 = _q1Options[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _q2Controller.dispose();
    _a1Controller.dispose();
    _a2Controller.dispose();
    _q3Controller.dispose();
    _a3Controller.dispose();
    super.dispose();
  }

  void _handleSignup(BuildContext context) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final a1 = _a1Controller.text.trim();
    final q2 = _q2Controller.text.trim();
    final a2 = _a2Controller.text.trim();
    final q3 = _q3Controller.text.trim();
    final a3 = _a3Controller.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty ||
        _selectedQ1 == null || a1.isEmpty || q2.isEmpty || a2.isEmpty || q3.isEmpty || a3.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields including security questions')),
      );
      return;
    }

    context.read<SignupBloc>().add(SignupSubmitted(
          fullName: name,
          email: email,
          phone: phone,
          password: password,
          q1: _selectedQ1!,
          a1: a1,
          q2: q2,
          a2: a2,
          q3: q3,
          a3: a3,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupBloc(userService: UserService()),
      child: BlocListener<SignupBloc, SignupState>(
        listener: (context, state) {
          if (state is SignupSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
              (route) => false,
            );
          } else if (state is SignupFailure) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(_nameController, 'Full Name', Icons.person, false),
                  const SizedBox(height: 15),
                  _buildTextField(_emailController, 'Email', Icons.email, false),
                  const SizedBox(height: 15),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone, false),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, 'Password', Icons.lock, true),
                  
                  const SizedBox(height: 30),
                  const Text(
                    'Security Questions',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  
                  // Question 1 (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedQ1,
                        isExpanded: true,
                        dropdownColor: Colors.brown[800],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: _q1Options.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedQ1 = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(_a1Controller, 'Answer to Question 1', Icons.question_answer, false),
                  
                  const SizedBox(height: 20),
                  _buildTextField(_q2Controller, 'Security Question 2 (Custom)', Icons.help_outline, false),
                  const SizedBox(height: 10),
                  _buildTextField(_a2Controller, 'Answer to Question 2', Icons.question_answer, false),
                  
                  const SizedBox(height: 20),
                  _buildTextField(_q3Controller, 'Security Question 3 (Custom)', Icons.help_outline, false),
                  const SizedBox(height: 10),
                  _buildTextField(_a3Controller, 'Answer to Question 3', Icons.question_answer, false),
                  
                  const SizedBox(height: 40),
                  BlocBuilder<SignupBloc, SignupState>(
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
                          onPressed: state is SignupLoading ? null : () => _handleSignup(context),
                          child: state is SignupLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('SIGN UP',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
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
}

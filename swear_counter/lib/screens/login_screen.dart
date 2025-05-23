import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../services/auth_service.dart';
import 'app_root.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        // Let Firebase Auth state listener handle navigation
        print("Google sign-in successful for user: ${user.displayName}");
      }
    } catch (e) {
      if (mounted) {
        _showError("Google sign-in failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loginWithEmail() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _showError("Please enter both email and password");
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (result.user != null) {
        // Let Firebase Auth state listener handle navigation
        print("Email sign-in successful for user: ${result.user?.email}");
      }
    } catch (e) {
      if (mounted) {
        _showError("Email sign-in failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.security, color: Colors.deepPurpleAccent, size: 60),
                const SizedBox(height: 16),
                Text("Swear Counter",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 30),

                // Email field
                TextField(
                  controller: _email,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 10),

                // Password field
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 20),

                // Email login button
                _isLoading 
                  ? const CircularProgressIndicator(color: Colors.deepPurple)
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _loginWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          child: const Text("Login with Email"),
                        ),
                        const SizedBox(height: 20),

                        // Official Google Sign-In Button
                        SignInButton(
                          Buttons.google,
                          onPressed: _loginWithGoogle,
                          text: "Sign in with Google",
                        ),
                      ],
                    ),
                
                const SizedBox(height: 16),

                // Navigation to sign-up
                TextButton(
                  onPressed: !_isLoading ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                  } : null,
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

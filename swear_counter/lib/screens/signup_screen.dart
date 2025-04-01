import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController username = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => isLoading = true);
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      await userCred.user?.updateDisplayName(username.text);
      await userCred.user?.reload();

      Navigator.pop(context); // Back to login
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${e.message}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Sign up", style: GoogleFonts.poppins(fontSize: 28, color: Colors.white)),
              const SizedBox(height: 20),
              TextFormField(
                controller: username,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) => value!.isEmpty ? "Username required" : null,
              ),
              TextFormField(
                controller: email,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Email required" : null,
              ),
              TextFormField(
                controller: password,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) => value!.length < 6 ? "Min 6 characters" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                ),
                onPressed: isLoading ? null : signUp,
                child: Text(isLoading ? "Creating..." : "Create Account"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

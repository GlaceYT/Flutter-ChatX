// ignore_for_file: use_build_context_synchronously
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String message) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _login() async {
    final id = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      _showAlert('Please enter both identifier and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(Filter.or(
            Filter('username', isEqualTo: id),
            Filter('email', isEqualTo: id),
            Filter('phone', isEqualTo: id),
          ))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showAlert('❌ No user found with provided credentials');
        return;
      }

      final doc = querySnapshot.docs.first;
      final userData = doc.data();

      if (userData['password'] != password) {
        _showAlert('❌ Incorrect password');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', doc.id);

      debugPrint("✅ Login success for user: ${userData['username']}");
      context.go('/tabs');
    } catch (e) {
      _showAlert('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    body: Stack(
      children: [
        // 🌌 Background image
        Positioned.fill(
          child: Image.asset(
            'assets/login.png', // Your background image
            fit: BoxFit.cover,
          ),
        ),

        // 📦 Content layered on top
        Column(
          children: [
            // 🔝 Header Image
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Image.asset(
                'assets/login.png',
                fit: BoxFit.cover,
              ),
            ),

            // 🧾 Flexible Form Box (fills remaining space)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(197, 255, 255, 255),
                      Color.fromARGB(255, 160, 160, 160),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text.rich(
  TextSpan(
    text: "Welcome to ",
    style: theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    children: [
      TextSpan(
        text: "ChatX",
        style: TextStyle(
          color: Colors.deepPurple, // 👈 Custom color for "ChatX"
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),

                      const SizedBox(height: 8),
                      Text(
                        "Please log in to continue",
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                      ),
                      const SizedBox(height: 32),

                      // 👤 Identifier Field
                      TextField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          hintText: 'Email / Username / Phone',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔐 Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 🔘 Login Button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // 📝 Register Option
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register-step1'),
                          child: const Text.rich(
                            TextSpan(
                              text: "Don't have an account? ",
                              children: [
                                TextSpan(
                                  text: "Register",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 231, 27, 88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


}

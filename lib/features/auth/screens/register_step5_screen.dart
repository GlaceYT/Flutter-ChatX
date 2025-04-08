import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class RegisterStep5Screen extends StatefulWidget {
  final String name;
  final String username;
  final String email;
  final String phone;

  const RegisterStep5Screen({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
  });

  @override
  State<RegisterStep5Screen> createState() => _RegisterStep5ScreenState();
}

class _RegisterStep5ScreenState extends State<RegisterStep5Screen> {
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _isSaving = false;
  String? _base64Image;
  bool _obscurePassword = true;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40, // Lower quality to reduce size
        maxWidth: 400,    // Smaller dimensions
        maxHeight: 400,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        
        // Convert image to base64
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imageBytes = bytes;
          _base64Image = base64String;
        });
        
        // Log the size for debugging
        debugPrint('📸 Image size (Base64): ${(base64String.length / 1024).toStringAsFixed(2)} KB');
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Failed to pick image: $e', style: const TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  bool _isValidPassword(String password) {
    // At least 8 characters with at least one letter and one number
    return password.length >= 8 && 
           password.contains(RegExp(r'[a-zA-Z]')) && 
           password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _submitRegistration() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please create a password to continue',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Password must be at least 8 characters with letters and numbers',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 🔄 Generate a new userId manually
      final userId = FirebaseFirestore.instance.collection('users').doc().id;

      // Create user data map
      final userData = {
        'name': widget.name,
        'username': widget.username,
        'email': widget.email,
        'phone': widget.phone,
        'password': password, // Note: storing passwords in plaintext is not secure
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Add the base64 image if available
      final base64 = _base64Image;
      if (base64 != null) {
        userData['profileImageBase64'] = base64;
      }

      // 📝 Save everything in one go
      await FirebaseFirestore.instance.collection('users').doc(userId).set(userData);

      // 💾 Save user ID/token locally for auth
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', userId);

      debugPrint('✅ User created with image and data!');
      if (!mounted) return;

      context.go('/tabs');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Registration failed: $e', style: const TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            backgroundImage:
                _imageBytes != null ? MemoryImage(_imageBytes!) : null,
            child: _imageBytes == null
                ? const Icon(Icons.person, size: 50, color: Colors.white70)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0D),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0A0D),
                const Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Step indicator with premium styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'FINAL STEP',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Heading with improved style
                const Text(
                  'COMPLETE YOUR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'PROFILE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '!',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Avatar upload section
                Center(
                  child: Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        'Add a profile picture',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Password input with enhanced styling
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.deepPurple,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[500],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[500],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                    ),
                  ),
                ),
                
                // Password requirements note
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'At least 8 characters with letters and numbers',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Complete button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isSaving
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                            strokeWidth: 3,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Complete Registration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline, size: 18),
                            ],
                          ),
                        ),
                ),
                
                const Spacer(),
                
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
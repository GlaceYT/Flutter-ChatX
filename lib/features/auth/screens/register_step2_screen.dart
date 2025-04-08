import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String name;

  const RegisterStep2Screen({super.key, required this.name});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSaving = false;

  Future<bool> _isUsernameTaken(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }
  bool _isValidUsername(String username) {
  // Only allows letters, numbers, underscores, and dots
  // Cannot end with symbols (underscore or dot)
  // Cannot contain spaces
  final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
  final RegExp endsWithSymbolRegex = RegExp(r'[._]$');
  
  return validUsernameRegex.hasMatch(username) && 
         !endsWithSymbolRegex.hasMatch(username) &&
         !username.contains(' ');
}
  Future<void> _validateAndProceed() async {
  final username = _usernameController.text.trim();
  
  if (username.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please enter a username to continue',
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
  
  if (!_isValidUsername(username)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Username can only contain letters, numbers, dots, and underscores. Cannot end with a symbol.',
                style: TextStyle(color: Colors.white),
              ),
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

  if (await _isUsernameTaken(username)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Username already taken',
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
    setState(() => _isSaving = false);
    return;
  }

  setState(() => _isSaving = false);
  context.push('/register-step3', extra: {
    'name': widget.name,
    'username': username,
  });
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
                    'STEP 2 OF 5',
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
                  'CREATE YOUR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'USERNAME',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      '.',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                
                // Welcome message with name
                Text(
                  'Welcome, ${widget.name}! Choose a unique username that represents you.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // Username input with enhanced styling
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.deepPurple,
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Colors.grey[500],
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
                
                // Username hints
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8),
                  child: Text(
                    '• No spaces allowed\n• Can contain letters, numbers and underscores',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Premium next button
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
                          onPressed: _validateAndProceed,
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
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
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
                        color: Colors.deepPurple,
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
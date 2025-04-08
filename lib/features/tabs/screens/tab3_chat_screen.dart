import 'package:flutter/material.dart';

class Tab3Screen extends StatelessWidget {
  const Tab3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E), // Deep purple background
      
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white30),
              SizedBox(height: 16),
              Text(
                '💖 POSTS',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Features coming soon...',
                style: TextStyle(fontSize: 16, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

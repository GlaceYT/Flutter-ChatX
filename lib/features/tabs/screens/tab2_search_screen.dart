// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tab2SearchScreen extends StatefulWidget {
  const Tab2SearchScreen({super.key});

  @override
  State<Tab2SearchScreen> createState() => _Tab2SearchScreenState();
}

class _Tab2SearchScreenState extends State<Tab2SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? currentUsername;
  List<DocumentSnapshot> _results = [];
  bool isLoading = false;

  @override
void initState() {
  super.initState();
  _loadCurrentUsername();

  _controller.addListener(() {
    final input = _controller.text.trim();
    if (input.isNotEmpty) {
      _searchUsers(input);
    } else {
      // 🧼 Clear results if input is empty
      setState(() {
        _results = [];
      });
    }
  });
}


Future<void> _loadCurrentUsername() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_token'); 

    if (userId == null) {
      print('⛔ Not logged in. Please login.');
      return;
    }

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!docSnapshot.exists) {
      print('⛔ User document not found');
      return;
    }

    final userData = docSnapshot.data() as Map<String, dynamic>;
    final usernameFromFirestore = userData['username'];

    setState(() {
      currentUsername = usernameFromFirestore;
    });

    print('🙋 Current username from Firestore: $currentUsername');

  } catch (e) {
    print('❌ Error loading username: $e');
  }
}


Future<void> _searchUsers(String query) async {
  if (query.isEmpty) return; // 🔐 Block empty searches

  setState(() {
    isLoading = true;
    _results = [];
  });

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .limit(50) // You can increase limit for larger search results
      .get();

  final searchText = query.toLowerCase();

  final filtered = snapshot.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final username = (data['username'] ?? '').toString().toLowerCase();
    final name = (data['name'] ?? '').toString().toLowerCase();

    if (currentUsername != null &&
        username == currentUsername!.toLowerCase()) {
      return false;
    }

    return username.contains(searchText) || name.contains(searchText);
  }).toList();

  setState(() {
    _results = filtered;
    isLoading = false;
  });
}



Future<void> _sendFriendRequest(String? toUsername) async {
  if (toUsername == null) return;

  // Lazy-load if not available
  if (currentUsername == null) {
    await _loadCurrentUsername();
    if (currentUsername == null) {
      print('⛔ Still no username');
      return;
    }
  }

  print('📤 Sending request from "$currentUsername" to "$toUsername"...');

  final userQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('username', isEqualTo: toUsername)
      .limit(1)
      .get();

  if (userQuery.docs.isEmpty) {
    print('⛔ No user found with username "$toUsername"');
    return;
  }

  final targetDoc = userQuery.docs.first.reference;

  await targetDoc.set({
    'friendRequests': {currentUsername!: true}
  }, SetOptions(merge: true));

  print('✅ Friend request sent!');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Friend request sent to @$toUsername')),
  );

  _searchUsers(_controller.text.trim());
}



 bool _alreadyRequested(DocumentSnapshot userDoc) {
  final data = userDoc.data() as Map<String, dynamic>;
  final friendRequests = data['friendRequests'] as Map<String, dynamic>? ?? {};
  return friendRequests.containsKey(currentUsername);
}


  Widget _buildUserCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[800],
          backgroundImage: data['profileImageBase64'] != null
              ? MemoryImage(base64Decode(data['profileImageBase64']))
              : null,
          child: data['profileImageBase64'] == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          data['name'] ?? 'Unnamed',
          style: const TextStyle(color: Colors.white),
        ),
       subtitle: Text(
  '@${data['username'] ?? 'unknown'}',
  style: const TextStyle(color: Colors.white70),
),

        trailing: ElevatedButton(
onPressed: _alreadyRequested(doc)
    ? null
    : () => _sendFriendRequest(data['username']),

          style: ElevatedButton.styleFrom(
            backgroundColor: _alreadyRequested(doc)
                ? Colors.grey
                : Colors.deepPurpleAccent,
          ),
          child: Text(
            _alreadyRequested(doc) ? 'Requested' : 'Add',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          else if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No users found',
                  style: TextStyle(color: Colors.white70)),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) => _buildUserCard(_results[index]),
              ),
            ),
        ],
      ),
    );
  }
}

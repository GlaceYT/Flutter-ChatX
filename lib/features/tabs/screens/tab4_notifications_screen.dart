import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tab4NotificationsScreen extends StatefulWidget {
  const Tab4NotificationsScreen({super.key});

  @override
  State<Tab4NotificationsScreen> createState() => _Tab4NotificationsScreenState();
}

class _Tab4NotificationsScreenState extends State<Tab4NotificationsScreen> {
  String? userId;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('user_token');

    if (storedUserId == null) {
      debugPrint('⛔ user_token not found');
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(storedUserId).get();
    if (!doc.exists) {
      debugPrint('⛔ user document not found');
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final username = data['username'];

    setState(() {
      userId = storedUserId;
      currentUsername = username;
    });

    debugPrint('🙋 Logged in as $currentUsername (ID: $userId)');
  }

  Future<void> _acceptFriendRequest(String fromUsername) async {
    if (userId == null || currentUsername == null) return;

    final userRef = FirebaseFirestore.instance.collection('users');

    await userRef.doc(userId).update({
      'friends.$fromUsername': true,
      'friendRequests.$fromUsername': FieldValue.delete(),
    });

    final requesterSnapshot = await userRef.where('username', isEqualTo: fromUsername).limit(1).get();
    if (requesterSnapshot.docs.isNotEmpty) {
      final requesterId = requesterSnapshot.docs.first.id;
      await userRef.doc(requesterId).update({
        'friends.$currentUsername': true,
      });
    }
  }

  Future<void> _declineFriendRequest(String fromUsername) async {
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'friendRequests.$fromUsername': FieldValue.delete(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep purple background
        appBar: AppBar(
        title: const Text('Alerts!'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: userId == null || currentUsername == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final requests = (data['friendRequests'] as Map<String, dynamic>?) ?? {};

                  if (requests.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline, size: 64, color: Colors.white30),
                            SizedBox(height: 16),
                            Text(
                              'No requests yet',
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please add friends in the Explore section 🔍',
                              style: TextStyle(fontSize: 14, color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final usernames = requests.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: usernames.length,
                    itemBuilder: (context, index) {
                      final requester = usernames[index];
                      return Card(
                        color: const Color(0xFF2C2C54), // Deeper purple for cards
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.person_add, color: Colors.white),
                          title: Text(
                            '@$requester',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Sent you a friend request',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.greenAccent),
                                onPressed: () => _acceptFriendRequest(requester),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                onPressed: () => _declineFriendRequest(requester),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

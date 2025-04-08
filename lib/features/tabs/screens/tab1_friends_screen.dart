import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/chat_screen_modal.dart';

class Tab1FriendsScreen extends StatefulWidget {
  const Tab1FriendsScreen({super.key});

  @override
  State<Tab1FriendsScreen> createState() => _Tab1FriendsScreenState();
}

class _Tab1FriendsScreenState extends State<Tab1FriendsScreen> {
  String? userDocId;
  String? currentUsername;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    if (token == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(token).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      userDocId = token;
      currentUsername = data['username'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0D),
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0D),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: userDocId == null || currentUsername == null
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userDocId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final friendsMap = data['friends'] as Map<String, dynamic>? ?? {};
                    final friendUsernames = friendsMap.keys.toList();

                    if (friendUsernames.isEmpty) {
                      return const Center(
                        child: Text('No friends yet 😔', style: TextStyle(color: Colors.white70)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: friendUsernames.length,
                      itemBuilder: (context, index) {
                        final friendUsername = friendUsernames[index];

                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('username', isEqualTo: friendUsername)
                              .limit(1)
                              .get(),
                          builder: (context, friendSnapshot) {
                            if (!friendSnapshot.hasData || friendSnapshot.data!.docs.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final friendDoc = friendSnapshot.data!.docs.first;
                            final friendData = friendDoc.data() as Map<String, dynamic>;

                     return Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.3),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.withOpacity(0.1)),
  ),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    leading: CircleAvatar(
      backgroundColor: Colors.deepPurple.withOpacity(0.2),
      backgroundImage: friendData['profileImageBase64'] != null
          ? MemoryImage(base64Decode(friendData['profileImageBase64']))
          : null,
      child: friendData['profileImageBase64'] == null
          ? const Icon(Icons.person, color: Colors.white70)
          : null,
    ),
    title: Text(
      friendData['name'] ?? friendUsername,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
    subtitle: Text('@$friendUsername', style: const TextStyle(color: Colors.white70)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(_generateChatId(currentUsername!, friendUsername))
              .collection('messages')
              .where('receiverId', isEqualTo: userDocId)
              .where('senderId', isEqualTo: friendDoc.id)
              .where('seen', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.data?.docs.length ?? 0;
            return Row(
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const Icon(Icons.chat_bubble_outline, color: Colors.deepPurpleAccent),
              ],
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF1E1E2F),
          onSelected: (value) async {
            final chatId = _generateChatId(currentUsername!, friendUsername);

           if (value == 'unfriend') {
  final batch = FirebaseFirestore.instance.batch();

  // Remove friend from current user's doc
  final currentUserRef = FirebaseFirestore.instance.collection('users').doc(userDocId);
  batch.update(currentUserRef, {
    'friends.$friendUsername': FieldValue.delete(),
  });

  // Remove current user from friend's doc
  final friendUserRef = FirebaseFirestore.instance.collection('users').doc(friendDoc.id);
  batch.update(friendUserRef, {
    'friends.$currentUsername': FieldValue.delete(),
  });

  // Delete chat messages
  final chatId = _generateChatId(currentUsername!, friendUsername);
  final messagesRef = FirebaseFirestore.instance
      .collection('chatRooms')
      .doc(chatId)
      .collection('messages');

  final messagesSnapshot = await messagesRef.get();
  for (final doc in messagesSnapshot.docs) {
    batch.delete(doc.reference);
  }

  // (Optional) Delete the chatRoom document itself
  final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatId);
  batch.delete(chatRoomRef);

  await batch.commit();
}

          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'unfriend',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text("Unfriend", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 10),
                  Text("Clear Chat", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    onTap: () async {
      final chatId = _generateChatId(currentUsername!, friendUsername);

      final unread = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userDocId)
          .where('senderId', isEqualTo: friendDoc.id)
          .where('seen', isEqualTo: false)
          .get();

      for (var doc in unread.docs) {
        doc.reference.update({'seen': true});
      }

showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) {
    return DraggableScrollableSheet(
      initialChildSize: 1,
      maxChildSize: 1,
      minChildSize: 1,
      expand: true,
      builder: (_, controller) {
        return ChatScreenModal(
          chatRoomId: chatId,
          currentUserId: userDocId!,
          friendUserId: friendDoc.id,
        );
      },
    );
  },
);



    },
  ),
);

                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _generateChatId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreenModal extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String friendUserId;

  const ChatScreenModal({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.friendUserId,
  });

  @override
  State<ChatScreenModal> createState() => _ChatScreenModalState();
}

class _ChatScreenModalState extends State<ChatScreenModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? friendName;
  String? friendUsername;
  String? friendProfileBase64;
  bool isLoadingFriend = true;

  @override
  void initState() {
    super.initState();
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendUserId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          friendName = data['name'] ?? 'No Name';
          friendUsername = data['username'] ?? 'unknown';
          friendProfileBase64 = data['profileImageBase64'];
          isLoadingFriend = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = {
      'text': text,
      'senderId': widget.currentUserId,
      'receiverId': widget.friendUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    };

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add(message);

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final message = {
        'imageBase64': base64Image,
        'senderId': widget.currentUserId,
        'receiverId': widget.friendUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      };

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(message);

      _scrollToBottom();
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          backgroundColor: Colors.deepPurpleAccent,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('EEE hh:mm a').format(date);
  }

  void _showFullScreenImage(String base64Image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                maxScale: 5.0,
                minScale: 0.5,
                child: Center(
                  child: SizedBox.expand(
                    child: Image.memory(
                      base64Decode(base64Image),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        left: 12,
        right: 12,
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _pickAndSendImage,
              icon: const Icon(Icons.image, color: Colors.deepPurpleAccent),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendTextMessage,
              icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingFriend) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepPurple.withOpacity(0.2),
                      backgroundImage: friendProfileBase64 != null
                          ? MemoryImage(base64Decode(friendProfileBase64!))
                          : null,
                      child: friendProfileBase64 == null
                          ? const Icon(Icons.person, color: Colors.white70)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friendName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@$friendUsername',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chatRooms')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data = messages[index].data() as Map<String, dynamic>;
                        final messageId = messages[index].id;
                        final isMe = data['senderId'] == widget.currentUserId;
                        final time = _formatTimestamp(data['timestamp']);
                        final imageBase64 = data['imageBase64'];
                        final hasImage = imageBase64 != null;
                        final text = data['text'];
                        final canDelete = isMe;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onLongPress: canDelete
                                    ? () => _showDeleteConfirmation(messageId)
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: hasImage
                                      ? const EdgeInsets.all(4)
                                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.deepPurpleAccent
                                        : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: hasImage
                                      ? GestureDetector(
                                          onTap: () => _showFullScreenImage(imageBase64),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.memory(
                                              base64Decode(imageBase64),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          text ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6),
                                child: Text(
                                  time,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input field
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }
}

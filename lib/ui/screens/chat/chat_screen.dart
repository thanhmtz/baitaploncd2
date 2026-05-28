import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  const ChatScreen({Key? key, required this.targetUid, required this.targetName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUid;
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createChatRoom();
    });
  }

  Future<void> _createChatRoom() async {
    if (_currentUid == null) return;
    
    try {
      // Create or get chat room
      final chatId1 = '${_currentUid}_${widget.targetUid}';
      final chatId2 = '${widget.targetUid}_${_currentUid}';
      
      final doc1 = await FirebaseFirestore.instance.collection('chats').doc(chatId1).get();
      final doc2 = await FirebaseFirestore.instance.collection('chats').doc(chatId2).get();
      
      if (doc1.exists) {
        _chatId = chatId1;
      } else if (doc2.exists) {
        _chatId = chatId2;
      } else {
        _chatId = chatId1;
        await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
          'participants': [_currentUid, widget.targetUid],
          'createdAt': FieldValue.serverTimestamp(),
          'unread_$_currentUid': 0,
          'unread_${widget.targetUid}': 0,
        });
      }
    } catch (e) {
      debugPrint('Error creating chat: $e');
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null || _currentUid == null) return;
    
    final text = _messageController.text.trim();
    
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
      'senderId': _currentUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update chat with last message
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
      'lastMessage': text,
      'lastSenderId': _currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Reset unread count for current user
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
      'unread_${_currentUid}': 0,
    });
    
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null && _currentUid == null
                ? const Center(child: Text('Error: Not logged in'))
                : _chatId == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('createdAt')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final messages = snapshot.data!.docs;
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages yet'));
                      }
                      
                      // Show notification for new messages
                      final lastMsg = messages.last.data();
                      if (lastMsg['senderId'] != _currentUid) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('New message from ${widget.targetName}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        });
                      }
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                      
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index].data();
                          final isMe = msg['senderId'] == _currentUid;
                          final timestamp = msg['createdAt'];
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      DateFormat.Hm().format(timestamp.toDate()),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : Colors.black54,
                                      ),
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
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
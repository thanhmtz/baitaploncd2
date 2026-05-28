import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_tracker/ui/screens/profile/user_profile_screen.dart';
import 'package:health_tracker/ui/screens/chat/chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notifications'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: TabBar(
                tabs: const [
                  Text('Notifications'),
                  Text('Messages'),
                ],
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [
                    Color.fromARGB(255, 255, 88, 128),
                    Color.fromARGB(255, 250, 124, 108),
                  ])),
                labelPadding: const EdgeInsets.symmetric(horizontal: 40),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _NotificationsTab(),
                  _MessagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data()!;
        final followers = (data['followers'] as List?)?.cast<String>() ?? [];
        final following = (data['following'] as List?)?.cast<String>() ?? [];
        
        if (followers.isEmpty) {
          return const Center(child: Text('No notifications'));
        }

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final uid = followers[index];
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, userSnap) {
                final userDoc = userSnap.data;
                if (userDoc == null) return const SizedBox();
                final user = userDoc;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['photoUrl'] ?? ''),
                  ),
                  title: Text('${user['username']} started following you'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(uid: uid),
                        ),
                      );
                    },
                    child: const Text('View'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(uid: uid),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MessagesTab extends StatefulWidget {
  const _MessagesTab();

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(child: Text('Please login'));
    }

    // Show all users with recent messages
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUid)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allChats = chatSnapshot.data!.docs;
        
        if (allChats.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.message, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No messages yet'),
              const SizedBox(height: 16),
              const Text('Go to Home and tap on a user to start chatting'),
            ],
          );
        }

var sortedChats = allChats.map((d) => d.data()).toList();
        
        return ListView.builder(
          itemCount: sortedChats.length,
          itemBuilder: (context, index) {
            final chat = sortedChats[index];
            final participants = (chat['participants'] as List).cast<String>();
            final otherUid = participants.firstWhere((u) => u != currentUid, orElse: () => participants.first);
            
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox();
                
                final userData = userSnap.data!.data();
                if (userData == null) return const SizedBox();
                
                final unreadCount = (chat['unread_$currentUid'] as int?) ?? 0;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userData['photoUrl'] ?? ''),
                  ),
                  title: Text(userData['username'] ?? ''),
                  subtitle: Row(
                    children: [
                      Expanded(child: Text(chat['lastMessage'] ?? '')),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.message),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          targetUid: otherUid,
                          targetName: userData['username'] ?? '',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
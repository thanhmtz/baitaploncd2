import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_tracker/data/repositories/firestore.dart';

class FollowScreen extends StatefulWidget {
  const FollowScreen({Key? key}) : super(key: key);

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      // Get current user data to know following list
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final following = List<String>.from(
          currentUserDoc.data()?['following'] ?? []);

      // Get all users except current
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUid)
          .get();

      final users = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        users.add(doc.data());
      }

      setState(() {
        _allUsers = users;
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allUsers.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _allUsers.length,
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    final uid = user['uid'] as String;
                    final isFollowing = _following.contains(uid);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          user['photoUrl'] ?? 'https://i.stack.imgur.com/l60Hf.png',
                        ),
                      ),
                      title: Text(user['username'] ?? 'User'),
                      subtitle: Text(user['bio'] ?? ''),
                      trailing: isFollowing
                          ? OutlinedButton(
                              onPressed: () => _unfollow(uid),
                              child: const Text('Following'),
                            )
                          : ElevatedButton(
                              onPressed: () => _follow(uid),
                              child: const Text('Follow'),
                            ),
                      onTap: () => _toggleFollow(uid),
                    );
                  },
                ),
    );
  }

  Future<void> _toggleFollow(String targetUid) async {
    if (_following.contains(targetUid)) {
      await _unfollow(targetUid);
    } else {
      await _follow(targetUid);
    }
  }

  Future<void> _follow(String targetUid) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final _firestore = FirebaseFirestore.instance;
      await _firestore.collection('users').doc(currentUid).update({
        'following': FieldValue.arrayUnion([targetUid]),
      });
      await _firestore.collection('users').doc(targetUid).update({
        'followers': FieldValue.arrayUnion([currentUid]),
      });

      setState(() {
        _following.add(targetUid);
      });
    } catch (e) {
      debugPrint('Follow error: $e');
    }
  }

  Future<void> _unfollow(String targetUid) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;

      final _firestore = FirebaseFirestore.instance;
      await _firestore.collection('users').doc(currentUid).update({
        'following': FieldValue.arrayRemove([targetUid]),
      });
      await _firestore.collection('users').doc(targetUid).update({
        'followers': FieldValue.arrayRemove([currentUid]),
      });

      setState(() {
        _following.remove(targetUid);
      });
    } catch (e) {
      debugPrint('Unfollow error: $e');
    }
  }
}
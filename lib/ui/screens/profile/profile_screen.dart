import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/shared/styles/themes.dart';
import 'package:health_tracker/ui/screens/profile/edit_profile_screen.dart';
import 'package:health_tracker/ui/screens/profile/follow_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _formatJoinedTime(DateTime? createdAt) {
    if (createdAt == null) return 'Recently';
    
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    return Scaffold(
      appBar: _getAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 3,
                  progressColor: const Color.fromARGB(255, 255, 108, 0),
                  percent: 0.7,
                  backgroundColor: Colors.transparent,
                  animation: true,
                  center: SizedBox(
                    height: 80,
                    width: 80,
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 30,
                  thickness: 10,
                  color: Colors.amber,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Joined',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          ,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      _formatJoinedTime(user.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          ,
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              user.username,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              user.bio,
            ),
            const SizedBox(height: 16),
            // Followers & Following
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn(
                  context,
                  '${user.followers?.length ?? 0}',
                  'Followers',
                  () => _showUsersList(context, 'followers'),
                ),
                const SizedBox(width: 32),
                _buildStatColumn(
                  context,
                  '${user.following?.length ?? 0}',
                  'Following',
                  () => _showUsersList(context, 'following'),
                ),
              ],
            ),
            Card(
              // margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 30,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: const Text('Profile'),
      centerTitle: true,
      actions: [
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem<int>(
              value: 0,
              child: Text('Edit Profile'),
            ),
            const PopupMenuItem<int>(
              value: 1,
              child: Text('Find Users'),
            ),
          ],
          onSelected: (value) {
            if (value == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            } else if (value == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FollowScreen(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _showUsersList(BuildContext context, String type) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uidList = type == 'followers'
        ? List<String>.from(userProvider.getUser.followers ?? [])
        : List<String>.from(userProvider.getUser.following ?? []);

    if (uidList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No $type yet')));
      return;
    }

    final users = <Map<String, dynamic>>[];
    for (final uid in uidList) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) users.add(doc.data()!);
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(user['photoUrl'] ?? '')),
            title: Text(user['username'] ?? ''),
          );
        },
      ),
    );
  }
}

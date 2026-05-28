import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/notifications_screen.dart';
import 'package:health_tracker/ui/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool treeMode;
  final Color treePrimary;
  final Color treeBackground;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.treeMode = false,
    this.treePrimary = const Color(0xFF5CE4D1),
    this.treeBackground = const Color(0xFF1A3A2F),
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50.0);

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    final backgroundColor = treeMode
        ? treeBackground.withOpacity(0.0)
        : Colors.transparent;

    final iconColor = treeMode ? Colors.white : null;
    final titleColor = treeMode ? Colors.white : null;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (!treeMode) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu, color: iconColor),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 48),
              ],
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor ?? Theme.of(context).appBarTheme.titleTextStyle?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications, color: iconColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(user.photoUrl),
                    backgroundColor: treePrimary,
                    radius: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

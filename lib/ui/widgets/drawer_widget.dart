import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/data/repositories/firebase_auth.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/about/about_screen.dart';
import 'package:health_tracker/ui/screens/profile/profile_screen.dart';
import 'package:health_tracker/ui/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    backgroundImage: NetworkImage(user.photoUrl),
                    radius: 35,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Profile
           ListTile(
    leading: const Icon(Icons.verified_user),
    title: Text(l10n.profile),
    onTap: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            uid: user.uid,
          ),
        ),
      );
    },
  ),

  /// About
  ListTile(
    leading: const Icon(Icons.info_outline),
    title: Text(l10n.about),
    onTap: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AboutScreen(),
        ),
      );
    },
  ),

  /// Settings
  ListTile(
    leading: const Icon(Icons.settings),
    title: Text(l10n.settings),
    onTap: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    },
  ),

  /// Feedback
  ListTile(
    leading: const Icon(Icons.border_color),
    title: const Text('Feedback'),
    onTap: () {
      Navigator.pop(context);
    },
  ),

  const Divider(),

  /// Logout
  ListTile(
    leading: const Icon(Icons.exit_to_app),
    title: Text(l10n.logout),
    onTap: () async {
      Navigator.pop(context);

      await FirebaseAuthRepo().logout();
    },
   ),
        ],
      ),
    );
  }
}
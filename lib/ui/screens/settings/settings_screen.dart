import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/shared/styles/themes.dart';
import 'package:health_tracker/ui/screens/settings/macro_config_screen.dart';
import 'package:health_tracker/widgets/language_selector.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({ Key? key }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(children: [
        const LanguageSelector(),
        ListTile(
          leading: const Icon(CupertinoIcons.moon_stars),
          title: Text(l10n.darkMode),
          trailing: Consumer<ThemeNotifier>(
            builder: (context, value, child) {
              return CupertinoSwitch(
                value: value.darkTheme,
                activeColor: Colors.red,
                onChanged: (newValue) {
                  value.toggleTheme();
                }
              );
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.pie_chart),
          title: const Text('Macro Goals'),
          subtitle: const Text('Set calorie & macro targets'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const MacroConfigScreen(),
          )),
        ),
      ],)
    );
  }
}
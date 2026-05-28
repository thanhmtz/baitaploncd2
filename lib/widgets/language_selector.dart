import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health_tracker/providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: DropdownButton<Locale>(
            value: localeProvider.locale,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: const Locale('vi'),
                child: Text(l10n.vietnamese),
              ),
              DropdownMenuItem(
                value: const Locale('en'),
                child: Text(l10n.english),
              ),
            ],
            onChanged: (locale) {
              if (locale != null) {
                localeProvider.setLocale(locale);
              }
            },
          ),
        );
      },
    );
  }
}
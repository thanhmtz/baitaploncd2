import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/ui/screens/auth/about/widgets/gender_picker_widget.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:numberpicker/numberpicker.dart';

class AboutContents {
  final String title;
  final String desc;
  final Widget body;
  // dynamic value;

  AboutContents({required this.title, required this.body, required this.desc});
}

List<AboutContents> getAboutContents(AppLocalizations l10n) => [
  AboutContents(
      title: l10n.aboutTitle1,
      desc: l10n.aboutDesc1,
      body: GenderPicker(onChanged: (_) {})),
  AboutContents(
    title: l10n.aboutTitle2,
    desc: l10n.aboutDesc2,
    body: NumberPicker(
      selectedTextStyle: const TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
      minValue: 0,
      maxValue: 140,
      value: 18,
      onChanged: (newValue) {},
    ),
  ),
  AboutContents(
    title: l10n.aboutTitle3,
    desc: l10n.aboutDesc3,
    body: HorizontalPicker(
      initialPosition: InitialPosition.start,
      minValue: 0,
      maxValue: 500,
      divisions: 1000,
      height: 150,
      onChanged: (newValue) {},
      suffix: 'kg',
      activeItemTextColor: Colors.red,
    ),
  ),
];

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingContents {
  final String title;
  final String image;
  final String desc;

  OnboardingContents(
      {required this.title, required this.image, required this.desc});
}

List<OnboardingContents> getOnboardingContents(AppLocalizations l10n) => [
  OnboardingContents(
    title: l10n.onboardingTitle1,
    image: "assets/illustrations/Fitness tracker-amico_red.png",
    desc: l10n.onboardingDesc1,
  ),
  OnboardingContents(
    title: l10n.onboardingTitle2,
    image: "assets/illustrations/Coaches-amico_red.png",
    desc: l10n.onboardingDesc2,
  ),
  OnboardingContents(
    title: l10n.onboardingTitle3,
    image: "assets/illustrations/Timeline-amico_red.png",
    desc: l10n.onboardingDesc3,
  ),
];
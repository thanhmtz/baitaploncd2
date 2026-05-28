import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/data/models/onboarding_model.dart';
import 'package:health_tracker/shared/constants/assets_path.dart';

enum Sex { male, female }

List<OnBoardingModel> getOnboardingList(AppLocalizations l10n) => [
  OnBoardingModel(
    img: MyAssets.onboradingone,
    title: l10n.manageYourTask,
    description: l10n.manageYourTaskDesc,
  ),
  OnBoardingModel(
    img: MyAssets.onboradingtwo,
    title: l10n.planYourDay,
    description: l10n.planYourDayDesc,
  ),
  OnBoardingModel(
    img: MyAssets.onboradingthree,
    title: l10n.accomplishYourGoals,
    description: l10n.accomplishYourGoalsDesc,
  ),
];
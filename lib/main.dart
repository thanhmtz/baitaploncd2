import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/shared/services/step_counter_service.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'package:health_tracker/ui/screens/auth/welcome_screen.dart';
import 'package:health_tracker/ui/widgets/indicator_widget.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/shared/styles/themes.dart';
import 'package:health_tracker/ui/widgets/navigation_widget.dart';
import 'package:provider/provider.dart';
import 'package:health_tracker/providers/locale_provider.dart';
import 'package:health_tracker/shared/services/fcm_service.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/notification_strings.dart';
import 'package:health_tracker/shared/services/reminder_service.dart';
import 'package:health_tracker/shared/services/smart_reminder_service.dart';
import 'package:health_tracker/shared/services/water_reminder_service.dart';
import 'package:health_tracker/shared/styles/animations.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();
  
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FcmService().initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light));

  StepCounterService().initialize();

  NotificationService().startOngoingHealthNotification();

  // Load locale for notification strings
  await NotificationStrings.load();

  // Load and schedule reminders
  await ReminderService().getReminders();

  // Load water reminders & schedule them
  await WaterReminderService().getReminders();

  runApp(const MyApp());

  // Smart reminders after app is running
  SmartReminderService().init();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  static const String title = 'Health Tracker';

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext context, Orientation orientation, deviceType) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: ((context) => ThemeNotifier())),
            ChangeNotifierProvider(create: ((_) => LocaleProvider())),
            ChangeNotifierProvider(create: ((_) => UserProvider())),
            ChangeNotifierProvider(create: ((_) => TreeProvider()..initialize())),
          ],
          child: Consumer2<ThemeNotifier, LocaleProvider>(
            builder: (context, themeNotifier, localeProvider, child) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                key: ValueKey(themeNotifier.darkTheme),
                title: title,
                debugShowCheckedModeBanner: false,
                theme: themeNotifier.darkTheme
                    ? MyThemes.darkTheme
                    : MyThemes.lightTheme,
                locale: localeProvider.locale,
                supportedLocales: const [
                  Locale('vi'),
                  Locale('en'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const MyCircularIndicator();
                      }
                      if (snapshot.hasData) {
                        return const Navigation();
                      }
                      return const WelcomeScreen();
                    }),
              );
            },
          ),
        );
      },
    );
  }
}
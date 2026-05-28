import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_tracker/shared/styles/colors.dart';
import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/user_provider.dart';
import 'package:health_tracker/ui/screens/diary/heart/meassure_bpm_screen.dart';
import 'package:health_tracker/ui/screens/diary/heart/heart_stats_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/add_meal_screen.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/calories_stats_screen.dart';
import 'package:health_tracker/ui/screens/diary/sleep/record_sleep_screen.dart';
import 'package:health_tracker/ui/screens/diary/sleep/sleep_stats_screen.dart';
import 'package:health_tracker/ui/screens/diary/water/add_water_screen.dart';
import 'package:health_tracker/ui/screens/diary/water/water_stats_screen.dart';
import 'package:health_tracker/ui/screens/diary/weight/add_weight_screen.dart';
import 'package:health_tracker/ui/screens/diary/blood_pressure/add_blood_pressure_screen.dart';
import 'package:health_tracker/ui/screens/diary/blood_pressure/blood_pressure_stats_screen.dart';
import 'package:health_tracker/ui/screens/diary/blood_sugar/add_blood_sugar_screen.dart';
import 'package:health_tracker/ui/screens/diary/blood_sugar/blood_sugar_stats_screen.dart';
import 'package:health_tracker/ui/screens/health_calculator/health_calculator_screen.dart';
import 'package:health_tracker/ui/screens/plans/meal_plan/meal_plan_screen.dart';
import 'package:health_tracker/ui/widgets/indicator_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:health_tracker/ui/widgets/step_counter_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:provider/provider.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> with WidgetsBindingObserver {
  // DateTime _selectedDate = DateTime.now();
  // DateTime _focusedDate = DateTime.now();
  // CalendarFormat _calendarFormat = CalendarFormat.week;
DateTime date = DateTime.now();
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  int _lastSavedBpm = 0;
  double _todaySleepHours = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}_${today.month}_${today.day}';
    
    await _fetchLatestBpm();
    
    _todaySleepHours = prefs.getDouble('sleep_duration_$todayKey') ?? 0;
    
    await _notificationService.initialize();
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _reloadSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    _todaySleepHours = prefs.getDouble('sleep_duration_${today.year}_${today.month}_${today.day}') ?? 0;
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadBpm();
    }
  }

  Future<void> _reloadBpm() async {
    final old = _lastSavedBpm;
    await _fetchLatestBpm();
    if (_lastSavedBpm != old && mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchLatestBpm() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_data')
          .doc('heart_rate')
          .collection('records')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _lastSavedBpm = (snapshot.docs.first.data()['bpm'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('Fetch BPM error: $e');
    }
  }

  double? get _goalCal {
    final user = context.read<UserProvider>().getUser;
    if (user?.goalCalories != null) return user!.goalCalories!.toDouble();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalCal = _goalCal ?? 2100;
    return Scaffold(
        // drawer: const NavDrawer(),
        // appBar: CustomAppBar(title: "Diary"),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: MyClipper(),
                child: Container(
                  height: 450,
                  decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? darkBlue
                          : Colors.transparent),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            DateTime.now().hour > 12 || DateTime.now().hour < 3
                                ? l10n.goodEvening
                                : l10n.goodMorning,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Text(
                            FirebaseAuth.instance.currentUser!.displayName!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 22),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              DateTime? newDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now());

                              if (newDate == null) return;

                              setState(() {
                                date = newDate;
                              });
                            },
                            child: Text(
                              DateFormat('d MMMM, y').format(date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )),
                      const SizedBox(
                        height: 30,
                      ),
                      const StepCounterWidget(),
                      // const SizedBox(
                      //   height: 12,
                      // ),
                      // ? DOUBLE COLUMN
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ? HEART CARD
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HeartStatsScreen(),
                                          ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Text(l10n.heartRate,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20))),
                                              IconButton(
                                                icon: const Icon(
                                                    FontAwesomeIcons.heartPulse,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const MeassureBPMScreen()));
                                                },
                                              )
                                            ],
                                          ),
                                          SizedBox(
                                            height: 100,
                                            width: double.infinity,
                                            child: LineChart(LineChartData(
                                              gridData: const FlGridData(show: false),
                                              titlesData:
                                                  const FlTitlesData(show: false),
                                              borderData:
                                                  FlBorderData(show: false),
                                              minX: 0,
                                              maxX: 11,
                                              minY: 0,
                                              maxY: 6,
                                              lineBarsData: [
                                                LineChartBarData(
                                                    spots: const [
                                                      FlSpot(0, 3),
                                                      FlSpot(1, 3),
                                                      FlSpot(1.3, 3.5),
                                                      FlSpot(1.6, 2.8),
                                                      FlSpot(2.2, 4.5),
                                                      FlSpot(2.6, 1.5),
                                                      FlSpot(3, 3.3),
                                                      FlSpot(3.2, 3),
                                                      // second beat
                                                      FlSpot(4, 3),
                                                      FlSpot(4.3, 3.5),
                                                      FlSpot(4.6, 2.8),
                                                      FlSpot(5.2, 4.2),
                                                      FlSpot(5.6, 1.9),
                                                      FlSpot(6, 3.3),
                                                      FlSpot(6.2, 3),
                                                      // third beat
                                                      FlSpot(7, 3),
                                                      FlSpot(7.3, 3.5),
                                                      FlSpot(7.6, 2.8),
                                                      FlSpot(8.2, 4.7),
                                                      FlSpot(8.6, 2),
                                                      FlSpot(9, 3.3),
                                                      FlSpot(9.2, 3),
                                                      FlSpot(10, 3),
                                                    ],
                                                    color: const Color.fromARGB(
                                                        255, 220, 18, 18),
                                                    // gradient: const LinearGradient(
                                                    //   colors: [
                                                    //     Colors.red,
                                                    //     Colors.transparent
                                                    //   ],
                                                    //   begin: Alignment.centerLeft,
                                                    //   end: Alignment.centerRight,
                                                    // ),
                                                    barWidth: 2,
                                                    isStrokeCapRound: true,
                                                    dotData: const FlDotData(
                                                      show: false,
                                                    ),
                                                    belowBarData: BarAreaData(
                                                        show: true,
                                                        gradient: RadialGradient(
                                                            radius: 1.6,
                                                            center: Alignment
                                                                .topCenter,
                                                            colors: [
                                                              const Color.fromARGB(
                                                                      255,
                                                                      220,
                                                                      18,
                                                                      18)
                                                                  .withOpacity(
                                                                      0.3),
                                                              // const Color(0xff02d39a)
                                                              //     .withOpacity(0.3),
                                                              Colors.transparent
                                                            ])
                                                        // LinearGradient(
                                                        //   colors: [
                                                        //     const Color(0xff23b6e6)
                                                        //         .withOpacity(0.3),
                                                        //     const Color(0xff02d39a)
                                                        //         .withOpacity(0.3),
                                                        //     Colors.transparent
                                                        //   ],
                                                        //   begin: Alignment.topCenter,
                                                        //   end: Alignment.bottomCenter,
                                                        //   transform: GradientTransform.,
                                                        // ),
                                                        ))
                                              ],
                                            )),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                _lastSavedBpm > 0 ? '$_lastSavedBpm' : '--',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24),
                                              ),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Text(
                                                l10n.bpm,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.grey.shade600),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // ? WATER CARD
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const WaterStatsScreen(),
                                          ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: StreamBuilder<Object>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(FirebaseAuth
                                                  .instance.currentUser!.uid)
                                              .collection('diary')
                                              .doc(DateFormat('d-M-y')
                                                  .format(date))
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot snapshot) {
                                            if (!snapshot.hasData) {
                                              return const MyCircularIndicator();
                                            } else {
                                              late dynamic water;
                                              if (!snapshot.data!.exists ||
                                                  !snapshot.data!
                                                      .data()!
                                                      .containsKey('water')) {
                                                water = 0;
                                              } else {
                                                water = snapshot.data!
                                                        .get('water') /
                                                    1000;
                                              }
                                              return Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child: Text(
                                                        l10n.water,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20),
                                                      )),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.water_drop,
                                                          color: Color.fromARGB(
                                                              255,
                                                              84,
                                                              184,
                                                              252),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const AddWaterScreen()));
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 100,
                                                    width: 150,
                                                    child:
                                                        LineChart(LineChartData(
                                                      gridData: const FlGridData(
                                                          show: false),
                                                      titlesData: const FlTitlesData(
                                                          show: false),
                                                      borderData: FlBorderData(
                                                          show: false),
                                                      minX: 0,
                                                      maxX: 11,
                                                      minY: 0,
                                                      maxY: 6,
                                                      lineBarsData: [
                                                        LineChartBarData(
                                                            spots: const [
                                                              FlSpot(0, 3),
                                                              FlSpot(2.6, 2),
                                                              FlSpot(4.9, 5),
                                                              FlSpot(6.8, 3.1),
                                                              FlSpot(8, 4),
                                                              FlSpot(9.5, 3),
                                                              FlSpot(11, 4),
                                                            ],
                                                            isCurved: true,
                                                            gradient:
                                                                const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xff23b6e6),
                                                                Color(
                                                                    0xff02d39a)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                            ),
                                                            barWidth: 5,
                                                            isStrokeCapRound:
                                                                true,
                                                            dotData: const FlDotData(
                                                              show: false,
                                                            ),
                                                            belowBarData: BarAreaData(
                                                                show: true,
                                                                gradient: RadialGradient(radius: 1.2, center: Alignment.topCenter, colors: [
                                                                  const Color(
                                                                          0xff23b6e6)
                                                                      .withOpacity(
                                                                          0.3),
                                                                  const Color(
                                                                          0xff02d39a)
                                                                      .withOpacity(
                                                                          0.3),
                                                                  Colors
                                                                      .transparent
                                                                ])
                                                                // LinearGradient(
                                                                //   colors: [
                                                                //     const Color(0xff23b6e6)
                                                                //         .withOpacity(0.3),
                                                                //     const Color(0xff02d39a)
                                                                //         .withOpacity(0.3),
                                                                //     Colors.transparent
                                                                //   ],
                                                                //   begin: Alignment.topCenter,
                                                                //   end: Alignment.bottomCenter,
                                                                //   transform: GradientTransform.,
                                                                // ),
                                                                ))
                                                      ],
                                                    )),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        water.toString(),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 24),
                                                      ),
                                                      const SizedBox(
                                                        width: 4,
                                                      ),
                                                      Text(
                                                        'ltr',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .grey.shade600),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              );
                                            }
                                          }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                // ? NUTRITION CARD
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CaloriesStatsScreen(date: date),
                                          ));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: StreamBuilder<Object>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(FirebaseAuth
                                                  .instance.currentUser!.uid)
                                              .collection('diary')
                                              .doc(DateFormat('d-M-y')
                                                  .format(date))
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const MyCircularIndicator();
                                            } else {
                                              late double calories = 0,
                                                  protein = 0,
                                                  carbs = 0,
                                                  fat = 0;
                                              if (snapshot.data!.exists) {
                                                if (snapshot.data!
                                                    .data()!
                                                    .containsKey(
                                                        'totalCalories')) {
                                                  calories = snapshot.data!
                                                      .get('totalCalories');
                                                }
                                                if (snapshot.data!
                                                    .data()!
                                                    .containsKey(
                                                        'totalProtein')) {
                                                  protein = snapshot.data!
                                                      .get('totalProtein');
                                                }
                                                if (snapshot.data!
                                                    .data()!
                                                    .containsKey('totalFat')) {
                                                  fat = snapshot.data!
                                                      .get('totalFat');
                                                }
                                                if (snapshot.data!
                                                    .data()!
                                                    .containsKey(
                                                        'totalCarbs')) {
                                                  carbs = snapshot.data!
                                                      .get('totalCarbs');
                                                }
                                              }
                                              return Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                          child: Text(
                                                              l10n.calories,
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      20))),
                                                      const Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Icon(
                                                          Icons
                                                              .local_fire_department,
                                                          color: Color.fromARGB(
                                                              255,
                                                              248,
                                                              105,
                                                              51),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 16,
                                                  ),
                                                  SizedBox(
                                                    height: 100,
                                                    width: 150,
                                                    child:
                                                        CircularPercentIndicator(
                                                      reverse: true,
                                                      radius: 45,
                                                      lineWidth: 7,
                                                      animation: true,
                                                      percent: calories < goalCal
                                                          ? calories / goalCal
                                                          : 1,
                                                      center: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                           Text(
                                                             calories.toStringAsFixed(0),
                                                             style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 22),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(l10n.kcal,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade500)),
                                                        ],
                                                      ),
                                                      backgroundColor: Colors
                                                          .grey.shade800
                                                          .withOpacity(0.3),
                                                      linearGradient:
                                                          const LinearGradient(
                                                              colors: [
                                                            Color.fromARGB(255,
                                                                255, 209, 59),
                                                            Color.fromARGB(255,
                                                                248, 105, 51),
                                                          ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomLeft),
                                                      circularStrokeCap:
                                                          CircularStrokeCap
                                                              .round,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 8,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          const Icon(
                                                              FontAwesomeIcons
                                                                  .bowlRice,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      250,
                                                                      109,
                                                                      77),
                                                              size: 16),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(l10n.carbs,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      8)),
                                                        ],
                                                      ),
                                                      Column(
                                                        children: [
                                                          const Icon(FontAwesomeIcons.cheese,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      151,
                                                                      161,
                                                                      255),
                                                              size: 16),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(l10n.fat,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      8)),
                                                        ],
                                                      ),
                                                      Column(
                                                        children: [
                                                          const Icon(
                                                              FontAwesomeIcons
                                                                  .fish,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      247,
                                                                      105,
                                                                      132),
                                                              size: 16),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(l10n.protein,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      8)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Text(
                                                        '${carbs.toStringAsFixed(0)}${l10n.gram}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 8),
                                                      ),
                                                      Text(
                                                        '${fat.toStringAsFixed(0)}${l10n.gram}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 8),
                                                      ),
                                                      Text(
                                                        '${protein.toStringAsFixed(0)}${l10n.gram}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 8),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }
                                          }),
                                    ),
                                  ),
                                ),
                                // ? SLEEP CARD
                                Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SleepStatsScreen(),
                                          ));
                                      _reloadSleep();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                l10n.sleep,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              )),
                                              IconButton(
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const RecordSleepScreen()));
                                                    _reloadSleep();
                                                  },
                                                  icon: const Icon(
                                                    CupertinoIcons
                                                        .moon_stars_fill,
                                                    color: Color.fromARGB(
                                                        255, 255, 200, 38),
                                                  ))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 32,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                _todaySleepHours > 0
                                                    ? _todaySleepHours.toStringAsFixed(1)
                                                    : '--',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24),
                                              ),
                                              const SizedBox(
                                                width: 4,
                                              ),
                                              Text(
                                                l10n.sleepHours,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.grey.shade600),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      // ? BLOOD PRESSURE CARD
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BloodPressureStatsScreen(),
                                    ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                      l10n.bloodPressure,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    )),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const AddBloodPressureScreen()));
                                      },
                                    )
                                  ]),
                                  SizedBox(
                                    height: 80,
                                    width: double.infinity,
                                    child: StreamBuilder<Object>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .collection('diary')
                                            .doc(DateFormat('d-M-y')
                                                .format(date))
                                            .snapshots(),
                                        builder: (context,
                                            AsyncSnapshot snapshot) {
                                          if (!snapshot.hasData) {
                                            return const MyCircularIndicator();
                                          }
                                          int systolic = 0, diastolic = 0;
                                          if (snapshot.data!.exists &&
                                              snapshot.data!.data()!
                                                  .containsKey(
                                                      'bloodPressure')) {
                                            final list = snapshot
                                                .data!.get('bloodPressure');
                                            if (list is List &&
                                                list.isNotEmpty) {
                                              final last = list.last;
                                              systolic =
                                                  (last['systolic'] as num?)
                                                          ?.toInt() ??
                                                      0;
                                              diastolic =
                                                  (last['diastolic'] as num?)
                                                          ?.toInt() ??
                                                      0;
                                            }
                                          }
                                          return Center(
                                            child: Text(
                                              systolic > 0
                                                  ? '$systolic/$diastolic'
                                                  : '--/--',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 28),
                                            ),
                                          );
                                        }),
                                  ),
                                  Text(
                                    l10n.mmHg,
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                ]),
                              ))),
                      // ? BLOOD SUGAR CARD
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BloodSugarStatsScreen(),
                                    ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                      l10n.bloodSugar,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    )),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.bloodtype,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const AddBloodSugarScreen()));
                                      },
                                    )
                                  ]),
                                  SizedBox(
                                    height: 80,
                                    width: double.infinity,
                                    child: StreamBuilder<Object>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .collection('diary')
                                            .doc(DateFormat('d-M-y')
                                                .format(date))
                                            .snapshots(),
                                        builder: (context,
                                            AsyncSnapshot snapshot) {
                                          if (!snapshot.hasData) {
                                            return const MyCircularIndicator();
                                          }
                                          double sugar = 0;
                                          if (snapshot.data!.exists &&
                                              snapshot.data!.data()!
                                                  .containsKey(
                                                      'bloodSugar')) {
                                            final list = snapshot
                                                .data!.get('bloodSugar');
                                            if (list is List &&
                                                list.isNotEmpty) {
                                              final last = list.last;
                                              sugar = (last['value'] as num?)
                                                      ?.toDouble() ??
                                                  0;
                                            }
                                          }
                                          return Center(
                                            child: Text(
                                              sugar > 0
                                                  ? sugar.toStringAsFixed(1)
                                                  : '--',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 28),
                                            ),
                                          );
                                        }),
                                  ),
                                  Text(
                                    l10n.mmol,
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                ]),
                              ))),
                      // ? MEAL PLAN CARD
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MealPlanScreen(),
                                    ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                      l10n.mealPlan,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    )),
                                    const Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.green,
                                    )
                                  ]),
                                  const SizedBox(height: 16),
                                  Icon(
                                    Icons.calendar_month,
                                    size: 36,
                                    color: Colors.green.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.tapToAddMeal,
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                ]),
                              ))),
                      // ? WEIGHT CARD
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                        l10n.weight,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      )),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.monitor_weight,
                                          color:
                                              Color.fromARGB(255, 92, 98, 255),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AddWeightScreen()));
                                        },
                                      )
                                    ],
                                  ),
                                  // ? WEIGHT CHART
                                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser!.uid)
                                        .collection('diary')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 180,
                                          width: double.infinity,
                                          child: Center(
                                            child: MyCircularIndicator(),
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return _buildWeightEmptyState(
                                          'Không tải được dữ liệu cân nặng',
                                        );
                                      }

                                      final records = _extractWeightRecords(
                                        snapshot.data?.docs ?? [],
                                      );

                                      return _buildWeightChart(records);
                                    },
                                  ),
                                ]),
                              ))),
                      // ? HEALTH CALCULATOR CARD
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HealthCalculatorScreen()));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.calculate,
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.healthCalculator,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.healthCalculatorSubtitle,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ]),
                              ))),
                    ],
                  )),
            ),
          ],
        ),
        floatingActionButton: FabCircularMenu(
          onDisplayChange: (isOpen) {
            BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10));
          },
          ringColor: Theme.of(context).scaffoldBackgroundColor,
          fabOpenIcon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          fabCloseIcon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          ringWidth: 130,
          fabCloseColor: Colors.red,
          fabOpenColor: Colors.grey.shade800,
          children: [
            RawMaterialButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeassureBPMScreen(),
                    ));
              },
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24.0),
              child: const Icon(
                FontAwesomeIcons.heartPulse,
              ),
            ),
            RawMaterialButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeassureBPMScreen(),
                    ));
              },
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24.0),
              child: const Icon(
                FontAwesomeIcons.heartPulse,
              ),
            ),
            RawMaterialButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(AppLocalizations.of(context)!.addMeal),
                          children: [
                            SimpleDialogOption(
                                child: Text(AppLocalizations.of(context)!.breakfast),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddMealScreen(
                                                title: 'Breakfast',
                                              )));
                                }),
                            SimpleDialogOption(
                                child: Text(AppLocalizations.of(context)!.lunch),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddMealScreen(
                                                  title: 'Lunch')));
                                }),
                            SimpleDialogOption(
                                child: Text(AppLocalizations.of(context)!.dinner),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddMealScreen(
                                                  title: 'Dinner')));
                                }),
                            SimpleDialogOption(
                                child: Text(AppLocalizations.of(context)!.snack),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AddMealScreen(
                                                  title: 'Snacks')));
                                }),
                          ],
                        );
                      });
                  // TODO: add food
                },
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24.0),
                child: const Icon(
                  Icons.restaurant,
                )),
            RawMaterialButton(
              onPressed: () {},
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24.0),
              child: const Icon(
                Icons.fitness_center,
              ),
            ),
            RawMaterialButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddWeightScreen(),
                      ));
                },
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24.0),
                child: const Icon(
                  Icons.monitor_weight,
                )),
            RawMaterialButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddWaterScreen(),
                    ));
              },
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24.0),
              child: const Icon(
                Icons.water_drop,
              ),
            ),
          ],
        ));
  }

  List<_WeightRecord> _extractWeightRecords(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final records = <_WeightRecord>[];

    for (final doc in docs) {
      final data = doc.data();
      final weight = _readWeightValue(data);
      final recordDate = _readWeightDate(doc.id, data);

      if (weight == null || weight <= 0 || recordDate == null) {
        continue;
      }

      records.add(
        _WeightRecord(
          date: DateTime(
            recordDate.year,
            recordDate.month,
            recordDate.day,
          ),
          weight: weight,
        ),
      );
    }

    records.sort((a, b) => a.date.compareTo(b.date));

    // Nếu một ngày có nhiều dữ liệu, giữ bản ghi cuối cùng của ngày đó.
    final mergedByDay = <String, _WeightRecord>{};
    for (final record in records) {
      final key = DateFormat('yyyy-MM-dd').format(record.date);
      mergedByDay[key] = record;
    }

    final merged = mergedByDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Chỉ hiển thị các mốc gần nhất để biểu đồ không bị rối.
    if (merged.length > 8) {
      return merged.sublist(merged.length - 8);
    }

    return merged;
  }

  double? _readWeightValue(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['weight'],
      data['Weight'],
      data['bodyWeight'],
      data['body_weight'],
      data['currentWeight'],
      data['current_weight'],
    ];

    for (final value in candidates) {
      final parsed = _toChartDouble(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  DateTime? _readWeightDate(String docId, Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['date'],
      data['createdAt'],
      data['updatedAt'],
      docId,
    ];

    for (final value in candidates) {
      final parsed = _toChartDate(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  double? _toChartDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }

    if (value is Map) {
      final map = Map<dynamic, dynamic>.from(value);
      return _toChartDouble(
        map['value'] ??
            map['weight'] ??
            map['kg'] ??
            map['bodyWeight'] ??
            map['currentWeight'],
      );
    }

    if (value is List && value.isNotEmpty) {
      return _toChartDouble(value.last);
    }

    return null;
  }

  DateTime? _toChartDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;

      final isoDate = DateTime.tryParse(text);
      if (isoDate != null) return isoDate;

      final formats = [
        DateFormat('d-M-y'),
        DateFormat('d-M-yyyy'),
        DateFormat('dd-MM-yyyy'),
        DateFormat('d/M/y'),
        DateFormat('d/M/yyyy'),
        DateFormat('yyyy-MM-dd'),
      ];

      for (final format in formats) {
        try {
          return format.parseStrict(text);
        } catch (_) {
          // Thử format tiếp theo.
        }
      }
    }

    return null;
  }

  String _formatChartWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildWeightEmptyState(String message) {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWeightChart(List<_WeightRecord> records) {
    if (records.isEmpty) {
      return _buildWeightEmptyState('Chưa có dữ liệu cân nặng');
    }

    final spots = <FlSpot>[
      for (int i = 0; i < records.length; i++)
        FlSpot(i.toDouble(), records[i].weight),
    ];

    final weights = records.map((item) => item.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    final yPadding = records.length == 1
        ? 2.0
        : ((maxWeight - minWeight) * 0.25).clamp(1.5, 6.0).toDouble();

    var minY = (minWeight - yPadding).floorToDouble();
    final maxY = (maxWeight + yPadding).ceilToDouble();

    if (minY < 0) minY = 0;

    final yRange = maxY - minY;
    final yInterval = (yRange / 4).clamp(1.0, 20.0).toDouble();
    final bottomStep = records.length <= 4 ? 1 : (records.length / 4).ceil();

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: records.length == 1 ? 1 : (records.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.18),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= records.length) {
                    return const SizedBox.shrink();
                  }

                  final shouldShow = index == 0 ||
                      index == records.length - 1 ||
                      index % bottomStep == 0;

                  if (!shouldShow) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d/M').format(records[index].date),
                      style: const TextStyle(
                        color: Color(0xff727272),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Color(0xff67727d),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt().clamp(0, records.length - 1).toInt();
                  final record = records[index];

                  return LineTooltipItem(
                    '${_formatChartWeight(record.weight)} kg\n'
                    '${DateFormat('d/M/y').format(record.date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: records.length > 2,
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 92, 98, 255),
                  Color.fromARGB(255, 73, 79, 255),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color.fromARGB(255, 92, 98, 255),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 92, 98, 255).withOpacity(0.28),
                    const Color.fromARGB(255, 92, 98, 255).withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _WeightRecord {
  const _WeightRecord({
    required this.date,
    required this.weight,
  });

  final DateTime date;
  final double weight;
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;

    final path = Path();

    path.moveTo(0, h);
    path.lineTo(0, 0); // 2. point
    path.quadraticBezierTo(w * 0.5, 200, w, 0);
    path.lineTo(w, h); // 5. point
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

Widget weightBottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color(0xff727272),
    // fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  Widget text;
  switch (value.toInt()) {
    case 0:
      text = Text(
          DateFormat('d/M')
              .format(DateTime.now().subtract(const Duration(days: 90))),
          style: style);
      break;
    case 1:
      text = Text(
          DateFormat('d/M')
              .format(DateTime.now().subtract(const Duration(days: 60))),
          style: style);
      break;
    case 2:
      text = Text(
          DateFormat('d/M')
              .format(DateTime.now().subtract(const Duration(days: 30))),
          style: style);
      break;
    case 3:
      text = Text(DateFormat('d/M').format(DateTime.now()), style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
}

Widget weightLeftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Color(0xff67727d),
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  String text;
  switch (value.toInt()) {
    case 40:
      text = '40';
      break;
    case 50:
      text = '50';
      break;
    case 60:
      text = '60';
      break;
    case 70:
      text = '70';
      break;
    case 80:
      text = '80';
      break;
    default:
      return Container();
  }

  return Text(text, style: style, textAlign: TextAlign.left);
}
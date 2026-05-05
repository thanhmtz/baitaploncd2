import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health_tracker/shared/services/step_counter_service.dart';
import 'package:health_tracker/ui/screens/diary/step/step_stats_screen.dart';

final _stepService = StepCounterService();

class StepCounterWidget extends StatelessWidget {
  final int stepGoal;
  
  const StepCounterWidget({
    Key? key,
    this.stepGoal = 12000,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stepService.watchTodaySteps(),
      initialData: _stepService.todaySteps,
      builder: (context, snapshot) {
        final steps = snapshot.data ?? 0;
        final walkingSteps = _stepService.walkingSteps;
        final runningSteps = _stepService.runningSteps;
        
        final walkingPercent = steps > 0 ? ((walkingSteps / steps) * 100).toInt() : 0;
        final runningPercent = steps > 0 ? ((runningSteps / steps) * 100).toInt() : 0;
        
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StepStatsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('Activity',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold))),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Today'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CircularPercentIndicator(
                          radius: 50,
                          lineWidth: 7,
                          animation: true,
                          animateFromLastPercent: true,
                          percent: steps < stepGoal
                              ? steps / stepGoal
                              : 1,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$steps',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22),
                              ),
                              const SizedBox(height: 2),
                              const Text('Steps',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.grey)),
                            ],
                          ),
                          backgroundColor: Colors.grey.shade800.withOpacity(0.3),
                          linearGradient: const LinearGradient(colors: [
                            Color.fromARGB(255, 224, 139, 27),
                            Colors.pink,
                          ]),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                      Expanded(
                        child: CircularPercentIndicator(
                          radius: 50,
                          lineWidth: 7,
                          animation: true,
                          percent: (steps / stepGoal).clamp(0, 1),
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (steps * 0.04).toInt().toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22),
                              ),
                              const SizedBox(height: 2),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department, size: 12),
                                  Text('kcal',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          backgroundColor: Colors.grey.shade800.withOpacity(0.3),
                          linearGradient: const LinearGradient(colors: [
                            Color.fromARGB(255, 224, 139, 27),
                            Colors.pink
                          ]),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color.fromARGB(255, 255, 150, 128)),
                          const SizedBox(height: 8),
                          const Text('Distance'),
                          const SizedBox(height: 4),
                          Text(
                            '${(steps * 7 ~/ 10000)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      _buildActivityColumn(
                        'Walking',
                        walkingPercent,
                        FontAwesomeIcons.personWalking,
                        walkingPercent >= 50 
                            ? const Color.fromARGB(255, 76, 175, 80)
                            : const Color.fromARGB(255, 249, 149, 76),
                      ),
                      _buildActivityColumn(
                        'Running',
                        runningPercent,
                        FontAwesomeIcons.personRunning,
                        runningPercent >= 20 
                            ? const Color.fromARGB(255, 76, 175, 80)
                            : const Color.fromARGB(255, 247, 105, 132),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityColumn(String label, int percent, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(label),
        const SizedBox(height: 4),
        Text(
          '$percent%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
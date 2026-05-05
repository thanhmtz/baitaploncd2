import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeartStatsScreen extends StatefulWidget {
  const HeartStatsScreen({Key? key}) : super(key: key);

  @override
  State<HeartStatsScreen> createState() => _HeartDetailsScreenState();
}

class _HeartDetailsScreenState extends State<HeartStatsScreen> {
  int _todayBpm = 0;
  String _healthStatus = 'Chưa đo';
  bool _isLoading = true;
  final List<int> _weekBpm = [];
  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _loadHeartData();
  }

  Future<void> _loadHeartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = '${now.year}_${now.month}_${now.day}';
      final key = 'heart_rate_$todayKey';
      _todayBpm = prefs.getInt(key) ?? 0;
      
      debugPrint('HeartStatsScreen - Loading BPM: $_todayBpm for key: $key');
      
      _healthStatus = _analyzeHealth(_todayBpm);
      await _loadWeekData();
    } catch (e) {
      debugPrint('Load heart data error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWeekData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      _weekBpm.clear();
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = 'heart_rate_${date.year}_${date.month}_${date.day}';
        _weekBpm.add(prefs.getInt(key) ?? 0);
      }
    } catch (e) {
      debugPrint('Load week data error: $e');
    }
  }

  String _analyzeHealth(int bpm) {
    if (bpm == 0) return 'Chưa đo';
    if (bpm < 60) return 'Thấp';
    if (bpm > 100) return 'Cao';
    return 'Bình thường';
  }

  Color _getStatusColor() {
    if (_todayBpm == 0) return Colors.grey;
    if (_todayBpm < 60) return Colors.blue;
    if (_todayBpm > 100) return Colors.orange;
    return Colors.green;
  }

  String _getHealthAdvice() {
    if (_todayBpm == 0) return 'Bạn chưa đo nhịp tim hôm nay.\nHãy đo ngay để theo dõi sức khỏe tim mạch!';
    if (_todayBpm < 60) {
      return '⚠️ Nhịp tim thấp có thể do:\n• Tập thể dục thường xuyên\n• Dùng thuốc tim\n• Ngủ không đủ giấc\n\n💡 Khuyến cáo:\nNếu kèm chóng mặt, mờ mắt,\nỉu xuống, hãy khám bác sĩ ngay!';
    }
    if (_todayBpm > 100) {
      return '⚠️ Nhịp tim nhanh có thể do:\n• Stress, lo âu\n• Caffeine, rượu bia\n• Sốt hoặc nhiễm trùng\n• Bệnh lý tim\n\n💡 Khuyến cáo:\nNghỉ ngơi, hạn chế caffeine,\ntheo dõi trong 30 phút!';
    }
    return '✅ Tim bạn khỏe mạnh!\n\n💡 Duy trì sức khỏe tim:\n• Tập thể dục đều đặn\n• Ăn ít đồ ngọt, béo\n• Ngủ đủ 7-8 tiếng/ngày\n• Giảm stress\n• Khám tim định kỳ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nhịp tim',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTodayCard(),
                  const SizedBox(height: 20),
                  _buildHealthAdvice(),
                  const SizedBox(height: 20),
                  _buildWeekChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildTodayCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(),
            _getStatusColor().withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _todayBpm < 60
                    ? Icons.arrow_downward
                    : _todayBpm > 100
                        ? Icons.favorite
                        : Icons.favorite,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _healthStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _todayBpm > 0 ? '$_todayBpm' : '--',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'BPM',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateTime.now().toString().split(' ')[0],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthAdvice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Đánh giá sức khỏe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getHealthAdvice(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7 ngày gần nhất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 150,
                minY: 40,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _weekDays.length) {
                          return Text(
                            _weekDays[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_weekBpm.length, (index) {
                  final bpm = _weekBpm[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bpm > 0 ? bpm.toDouble() : 0,
                        color: _analyzeHealth(bpm) == 'Bình thường'
                            ? Colors.green
                            : _analyzeHealth(bpm) == 'Cao'
                                ? Colors.orange
                                : _analyzeHealth(bpm) == 'Thấp'
                                    ? Colors.blue
                                    : Colors.grey,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green, 'Bình thường'),
              const SizedBox(width: 16),
              _buildLegend(Colors.orange, 'Cao'),
              const SizedBox(width: 16),
              _buildLegend(Colors.blue, 'Thấp'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
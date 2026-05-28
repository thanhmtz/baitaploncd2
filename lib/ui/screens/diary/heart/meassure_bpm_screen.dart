import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_tracker/shared/services/notification_service.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'heart_stats_screen.dart';

class MeassureBPMScreen extends StatefulWidget {
  const MeassureBPMScreen({Key? key}) : super(key: key);

  @override
  State<MeassureBPMScreen> createState() => _MeassureBPMScreenState();
}

class _MeassureBPMScreenState extends State<MeassureBPMScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool _isCameraStreaming = false;
  bool _isFrameBusy = false;

  bool _fingerOnCamera = false;
  bool _isCountingDown = false;
  bool _isMeasuring = false;
  bool _hasShownResult = false;
  bool _isSignalPaused = false;

  int _countdown = 3;
  int _bpm = 0;
  int _lastFrameMs = 0;
  int _lastUiUpdateMs = 0;
  int _lastEstimateMs = 0;
  int _stableFingerFrames = 0;
  int _badEstimateCount = 0;
  int _validSignalMs = 0;
  int? _lastValidFrameMs;

  int? _lastAcceptedBpm;

  double _measurementProgress = 0.0;

  String _status = 'Đang mở camera...';

  final List<double> _waveData = [];
  final List<int> _bpmHistory = [];
  final List<double> _ppgBuffer = [];
  final List<int> _timeBuffer = [];

  static const int _maxWaveData = 100;
  static const int _minValidSeconds = 10;
  static const int _recommendedSeconds = 25;
  static const int _maxPpgSamples = 500;

  static const int _requiredStableFingerFrames = 10;
  static const int _frameIntervalMs = 65;
  static const int _estimateEveryMs = 1000;
  static const int _maxSignalWindowMs = 18000;
  static const double _targetSampleRate = 15.0;

  // Đo nghỉ nên để 45 - 135 để tránh số ảo 160 - 170.
  // Nếu muốn đo sau vận động, có thể tăng _maxAllowedBpm lên 180.
  static const int _minAllowedBpm = 45;
  static const int _maxAllowedBpm = 135;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() => _status = 'Không tìm thấy camera');
        }
        return;
      }

      final backCam = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final imageFormatGroup = Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420;

      _cameraController = CameraController(
        backCam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _status = 'Đặt ngón tay che kín camera sau';
      });

      await _startFingerDetection();
    } catch (e) {
      debugPrint('Camera init error: $e');

      if (mounted) {
        setState(() => _status = 'Không thể mở camera');
      }
    }
  }

  Future<void> _startFingerDetection() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) {
      _isCameraStreaming = true;
      return;
    }

    try {
      await controller.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Torch error: $e');
    }

    try {
      await controller.startImageStream(_onCameraImage);
      _isCameraStreaming = true;

      if (mounted) {
        setState(() {
          _status = 'Đặt ngón tay che kín camera sau';
        });
      }
    } catch (e) {
      debugPrint('Start image stream error: $e');

      if (mounted) {
        setState(() => _status = 'Không thể đọc hình ảnh từ camera');
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_isFrameBusy || _hasShownResult) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Giới hạn xử lý khoảng 15 fps để giảm nhiễu và tránh lag.
    if (nowMs - _lastFrameMs < _frameIntervalMs) return;

    _lastFrameMs = nowMs;
    _isFrameBusy = true;

    try {
      final sample = _extractPpgSample(image);
      if (sample == null) return;

      if (!_isValidFingerFrame(sample)) {
        _handleInvalidFinger(sample, nowMs);
        return;
      }

      _handleValidFinger(sample, nowMs);
    } catch (e) {
      debugPrint('Camera frame error: $e');
    } finally {
      _isFrameBusy = false;
    }
  }

  void _handleInvalidFinger(_PpgFrameSample sample, int nowMs) {
    _stableFingerFrames = 0;
    _fingerOnCamera = false;

    if (_isCountingDown) {
      _cancelCountdown();
    }

    if (_isMeasuring) {
      _isSignalPaused = true;
      _lastValidFrameMs = null;
      _status = 'Mất tín hiệu. Đặt lại ngón tay để tiếp tục';
      _updateUiThrottled(nowMs, intervalMs: 160);
      return;
    }

    _isSignalPaused = false;
    _clearSignalData(resetProgress: true);
    _bpm = 0;
    _status = _fingerHelpText(sample);

    _updateUiThrottled(nowMs, intervalMs: 250);
  }

  void _handleValidFinger(_PpgFrameSample sample, int nowMs) {
    _stableFingerFrames++;

    if (_stableFingerFrames < _requiredStableFingerFrames) {
      _fingerOnCamera = false;

      if (_isMeasuring) {
        _isSignalPaused = true;
        _status = 'Tín hiệu trở lại. Giữ yên ngón tay...';
      } else {
        _status = 'Giữ yên ngón tay...';
      }

      _updateUiThrottled(nowMs, intervalMs: 250);
      return;
    }

    _fingerOnCamera = true;

    if (!_isMeasuring) {
      if (!_isCountingDown) {
        _startCountdown();
      }

      _updateUiThrottled(nowMs, intervalMs: 250);
      return;
    }

    _isSignalPaused = false;

    final frameDeltaMs = _lastValidFrameMs == null
        ? _frameIntervalMs
        : (nowMs - _lastValidFrameMs!).clamp(30, 200).toInt();

    _lastValidFrameMs = nowMs;

    final totalRequiredMs = _recommendedSeconds * 1000;
    _validSignalMs = min(totalRequiredMs, _validSignalMs + frameDeltaMs);
    _measurementProgress = _validSignalMs / totalRequiredMs;

    // Dùng trục thời gian hợp lệ thay vì wall-clock.
    // Khi mất tín hiệu, thời gian tín hiệu không tăng nên progress dừng đúng như UI.
    _pushPpgSample(sample.value, _validSignalMs);

    final filteredValue = _currentFilteredValue();
    _pushWaveSample(filteredValue);

    final signalSeconds = _timeBuffer.length >= 2
        ? (_timeBuffer.last - _timeBuffer.first) / 1000.0
        : 0.0;

    if (signalSeconds < _minValidSeconds) {
      _status = 'Đang lấy tín hiệu... ${(_measurementProgress * 100).round()}%';
    } else if (nowMs - _lastEstimateMs >= _estimateEveryMs) {
      _lastEstimateMs = nowMs;

      final estimatedBpm = _estimateBpmByAutocorrelation();
      final acceptedBpm =
          estimatedBpm == null ? null : _acceptBpmEstimate(estimatedBpm);

      if (acceptedBpm != null) {
        _badEstimateCount = 0;

        _bpmHistory.add(acceptedBpm);
        if (_bpmHistory.length > 10) {
          _bpmHistory.removeAt(0);
        }

        _bpm = _stableBpmFromHistory();
        _status = 'Đang đo... $_bpm BPM';
      } else {
        _badEstimateCount++;

        if (_bpm > 0 && _badEstimateCount < 5) {
          _status = 'Đang ổn định... $_bpm BPM';
        } else {
          _status = 'Tín hiệu yếu, giữ yên ngón tay';
        }
      }
    } else if (_bpm > 0) {
      _status = 'Đang đo... $_bpm BPM';
    } else {
      _status = 'Đang đo...';
    }

    if (_measurementProgress >= 1.0) {
      debugPrint('Progress reached 100%, calling _finishMeasurement with BPM: $_bpm');
      _finishMeasurement();
      return;
    } else if (_measurementProgress > 0.8) {
      debugPrint('Progress: ${(_measurementProgress * 100).round()}% - almost done, BPM: $_bpm');
    }

    _updateUiThrottled(nowMs, intervalMs: 120);
  }

  void _updateUiThrottled(int nowMs, {required int intervalMs}) {
    if (!mounted) return;

    if (nowMs - _lastUiUpdateMs > intervalMs) {
      _lastUiUpdateMs = nowMs;
      setState(() {});
    }
  }

  void _startCountdown() {
    if (_isCountingDown || _isMeasuring || _hasShownResult) return;

    _countdownTimer?.cancel();

    setState(() {
      _isCountingDown = true;
      _countdown = 3;
      _status = 'Đúng vị trí. Chuẩn bị đo...';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_fingerOnCamera || _stableFingerFrames < _requiredStableFingerFrames) {
        _cancelCountdown();
        return;
      }

      if (_countdown <= 1) {
        timer.cancel();
        _beginMeasurement();
        return;
      }

      setState(() {
        _countdown--;
        _status = 'Đúng vị trí. Chuẩn bị đo...';
      });
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (_isCountingDown && mounted) {
      setState(() {
        _isCountingDown = false;
        _countdown = 3;
      });
    } else {
      _isCountingDown = false;
      _countdown = 3;
    }
  }

  void _beginMeasurement() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _clearSignalData(resetProgress: true);

    setState(() {
      _isCountingDown = false;
      _isMeasuring = true;
      _isSignalPaused = false;
      _hasShownResult = false;
      _bpm = 0;
      _status = 'Bắt đầu đo. Giữ yên ngón tay';
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  Future<void> _finishMeasurement() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _pulseController.stop();
    _waveController.stop();

    if (_bpmHistory.isNotEmpty) {
      _bpm = _stableBpmFromHistory();
    }

    final hasResult = _bpm > 0;

    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _isMeasuring = false;
        _isSignalPaused = false;
        _fingerOnCamera = false;
        _hasShownResult = hasResult;
        _measurementProgress = hasResult ? 1.0 : _measurementProgress;
        _status = hasResult ? 'Xong: $_bpm BPM - ${_analyzeHeartRate()}' : 'Không đủ tín hiệu';
      });
    }

    await _stopCameraProcessing(turnOffFlash: true);

    debugPrint('FinishMeasurement: hasResult=$hasResult, bpm=$_bpm');

    if (hasResult && mounted) {
      debugPrint('Calling _autoSaveHeartRate...');
      await _autoSaveHeartRate();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HeartStatsScreen()),
        );
      }
    } else if (!hasResult && mounted) {
      // Just navigate even without result
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HeartStatsScreen()),
        );
      }
    }
  }

  Future<void> _autoSaveHeartRate() async {
    debugPrint('_autoSaveHeartRate called with bpm: $_bpm');
    
    if (_bpm <= 0) {
      debugPrint('BPM is 0, skipping save');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = '${now.year}_${now.month}_${now.day}';
      final key = 'heart_rate_$todayKey';
      final timeKey = '${key}_time';

      await prefs.setInt(key, _bpm);
      await prefs.setString(timeKey, now.toIso8601String());
      
      debugPrint('Saved heart rate: $_bpm BPM for key: $key');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_data')
            .doc('heart_rate')
            .collection('records')
            .add({
          'bpm': _bpm,
          'status': _analyzeHeartRate(),
          'timestamp': now,
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'hour': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        });
      }

      final currentSteps = prefs.getInt('current_steps') ?? 0;
      
      NotificationService().showHealthStatusNotification(
        bpm: _bpm,
      );

      // Give XP for heart rate measurement
      TreeService().addHeartXp();

      debugPrint('Auto-saved heart rate: $_bpm BPM - notification updated with steps: $currentSteps');
    } catch (e) {
      debugPrint('Auto-save heart rate error: $e');
    }
  }

  Future<void> _stopCameraProcessing({required bool turnOffFlash}) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      _isCameraStreaming = false;
    } catch (e) {
      debugPrint('Stop image stream error: $e');
    }

    if (turnOffFlash) {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (e) {
        debugPrint('Flash off error: $e');
      }
    }
  }

  _PpgFrameSample? _extractPpgSample(CameraImage image) {
    if (image.planes.isEmpty) return null;

    // iOS thường dùng BGRA.
    if (image.format.group == ImageFormatGroup.bgra8888) {
      final plane = image.planes.first;
      final bytes = plane.bytes;
      final bytesPerPixel = plane.bytesPerPixel ?? 4;
      final rowStride = plane.bytesPerRow;

      const step = 8;

      double sum = 0;
      double sumSq = 0;
      double rSum = 0;
      double gSum = 0;
      double bSum = 0;
      int count = 0;

      for (int y = 0; y < image.height; y += step) {
        for (int x = 0; x < image.width; x += step) {
          final index = y * rowStride + x * bytesPerPixel;
          if (index + 2 >= bytes.length) continue;

          final b = bytes[index].toDouble();
          final g = bytes[index + 1].toDouble();
          final r = bytes[index + 2].toDouble();

          final luminance = 0.299 * r + 0.587 * g + 0.114 * b;

          sum += luminance;
          sumSq += luminance * luminance;
          rSum += r;
          gSum += g;
          bSum += b;
          count++;
        }
      }

      if (count == 0) return null;

      final mean = sum / count;
      final variance = max(0.0, sumSq / count - mean * mean);
      final stdDev = sqrt(variance);
      final redMean = rSum / count;

      return _PpgFrameSample(
        value: redMean,
        mean: mean,
        stdDev: stdDev,
        redRatio: rSum / max(1.0, gSum + bSum),
      );
    }

    // Android thường dùng YUV420. Dùng kênh Y để lấy độ sáng.
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;

    const step = 8;

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final index = y * rowStride + x;
        if (index >= bytes.length) continue;

        final yValue = bytes[index].toDouble();

        sum += yValue;
        sumSq += yValue * yValue;
        count++;
      }
    }

    if (count == 0) return null;

    final mean = sum / count;
    final variance = max(0.0, sumSq / count - mean * mean);
    final stdDev = sqrt(variance);

    return _PpgFrameSample(
      value: mean,
      mean: mean,
      stdDev: stdDev,
    );
  }

  bool _isValidFingerFrame(_PpgFrameSample sample) {
    final enoughLight = sample.mean > 35 && sample.mean < 245;

    // Khi ngón tay che kín camera, ảnh thường đều.
    // stdDev cao nghĩa là bị hở sáng hoặc tay rung nhiều.
    final uniformFrame = sample.stdDev < 32;

    // Với BGRA, ảnh ngón tay + flash thường thiên đỏ.
    final redEnough = sample.redRatio == null || sample.redRatio! > 0.45;

    return enoughLight && uniformFrame && redEnough;
  }

  String _fingerHelpText(_PpgFrameSample sample) {
    if (sample.mean <= 35) {
      return 'Đặt ngón tay che kín camera sau';
    }

    if (sample.mean >= 245) {
      return 'Ánh sáng quá mạnh, đặt nhẹ tay hơn';
    }

    if (sample.stdDev >= 32) {
      return 'Che kín camera, tránh để hở sáng';
    }

    return 'Giữ yên ngón tay';
  }

  void _pushPpgSample(double value, int timeMs) {
    _ppgBuffer.add(value);
    _timeBuffer.add(timeMs);

    final overflow = _ppgBuffer.length - _maxPpgSamples;
    if (overflow > 0) {
      _ppgBuffer.removeRange(0, overflow);
      _timeBuffer.removeRange(0, overflow);
    }
  }

  void _pushWaveSample(double value) {
    _waveData.add(value);

    final overflow = _waveData.length - _maxWaveData;
    if (overflow > 0) {
      _waveData.removeRange(0, overflow);
    }
  }

  void _clearSignalData({required bool resetProgress}) {
    _ppgBuffer.clear();
    _timeBuffer.clear();
    _bpmHistory.clear();
    _waveData.clear();
    _lastAcceptedBpm = null;
    _badEstimateCount = 0;
    _lastEstimateMs = 0;
    _lastValidFrameMs = null;

    if (resetProgress) {
      _validSignalMs = 0;
      _measurementProgress = 0.0;
    }
  }

  double _currentFilteredValue() {
    if (_ppgBuffer.length < 5) return 0;

    final shortAvg = _avgLast(_ppgBuffer, min(4, _ppgBuffer.length));
    final longAvg = _avgLast(_ppgBuffer, min(40, _ppgBuffer.length));

    return shortAvg - longAvg;
  }

  double _avgLast(List<double> values, int count) {
    if (values.isEmpty) return 0;

    final start = max(0, values.length - count);
    double sum = 0;

    for (int i = start; i < values.length; i++) {
      sum += values[i];
    }

    return sum / (values.length - start);
  }

  int? _estimateBpmByAutocorrelation() {
    final n = _ppgBuffer.length;

    if (n < 120 || _timeBuffer.length != n) return null;

    final durationSec = (_timeBuffer.last - _timeBuffer.first) / 1000.0;
    if (durationSec < _minValidSeconds) return null;

    final resampled = _resampleUniform(
      _ppgBuffer,
      _timeBuffer,
      _targetSampleRate,
    );

    if (resampled.length < (_targetSampleRate * _minValidSeconds).round()) {
      return null;
    }

    final filtered = _buildFilteredSignal(resampled, _targetSampleRate);
    if (filtered.length < 100) return null;

    final mean = filtered.reduce((a, b) => a + b) / filtered.length;

    double variance = 0;
    for (final v in filtered) {
      final d = v - mean;
      variance += d * d;
    }

    variance /= filtered.length;
    final stdDev = sqrt(variance);

    // Tín hiệu quá phẳng hoặc quá nhiễu đều không đáng tin cậy.
    if (stdDev < 0.08 || stdDev > 30) return null;

    final normalized = List<double>.generate(
      filtered.length,
      (i) => (filtered[i] - mean) / stdDev,
    );

    final minLag = max(
      2,
      (_targetSampleRate * 60 / _maxAllowedBpm).ceil(),
    );

    final maxLag = min(
      normalized.length - 2,
      (_targetSampleRate * 60 / _minAllowedBpm).floor(),
    );

    if (maxLag <= minLag) return null;

    final correlations = <int, double>{};

    for (int lag = minLag; lag <= maxLag; lag++) {
      double sum = 0;
      double energyA = 0;
      double energyB = 0;

      for (int i = lag; i < normalized.length; i++) {
        final a = normalized[i];
        final b = normalized[i - lag];

        sum += a * b;
        energyA += a * a;
        energyB += b * b;
      }

      if (energyA <= 0 || energyB <= 0) continue;

      correlations[lag] = sum / sqrt(energyA * energyB);
    }

    if (correlations.isEmpty) return null;

    int? bestLag;
    double bestCorrelation = -1;
    double bestScore = -1;

    for (int lag = minLag; lag <= maxLag; lag++) {
      final c = correlations[lag];
      if (c == null) continue;

      if (lag > minLag && lag < maxLag) {
        final left = correlations[lag - 1] ?? c;
        final right = correlations[lag + 1] ?? c;

        if (c < left || c < right) continue;
      }

      if (c < 0.30) continue;

      final bpmValue = 60.0 * _targetSampleRate / lag;
      double score = c;

      if (_lastAcceptedBpm != null && _bpmHistory.length >= 3) {
        final diff = (bpmValue - _lastAcceptedBpm!).abs();

        if (diff > 22) {
          score *= 0.72;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestCorrelation = c;
        bestLag = lag;
      }
    }

    if (bestLag == null) return null;
    if (bestCorrelation < 0.34) return null;

    var finalLag = bestLag;
    var bpm = (60 * _targetSampleRate / finalLag).round();

    // Chống bắt nhầm harmonic: ví dụ 160 thay vì 80, 130 thay vì 65.
    final doubleLag = finalLag * 2;
    if (doubleLag <= maxLag) {
      final doubleLagCorr = correlations[doubleLag];

      if (doubleLagCorr != null && doubleLagCorr >= bestCorrelation * 0.60) {
        finalLag = doubleLag;
        bpm = (60 * _targetSampleRate / finalLag).round();
      }
    }

    final peakBpm = _estimateBpmByPeaks(normalized, _targetSampleRate);

    if (peakBpm != null && (peakBpm - bpm).abs() > 14) {
      return null;
    }

    if (peakBpm != null) {
      bpm = ((bpm * 0.7) + (peakBpm * 0.3)).round();
    }

    if (bpm < _minAllowedBpm || bpm > _maxAllowedBpm) return null;

    return bpm;
  }

  List<double> _resampleUniform(
    List<double> values,
    List<int> times,
    double targetFs,
  ) {
    if (values.length < 2 || times.length != values.length) return [];

    final lastMs = times.last;
    final startLimitMs = max(times.first, lastMs - _maxSignalWindowMs);

    int startIndex = 0;
    while (startIndex < times.length - 2 && times[startIndex] < startLimitMs) {
      startIndex++;
    }

    if (startIndex > 0) startIndex--;

    final localValues = values.sublist(startIndex);
    final localTimes = times.sublist(startIndex);

    if (localValues.length < 2) return [];

    final firstMs = max(localTimes.first, startLimitMs).toDouble();
    final endMs = localTimes.last.toDouble();
    final stepMs = 1000.0 / targetFs;

    final count = ((endMs - firstMs) / stepMs).floor() + 1;
    if (count < 2) return [];

    final result = List<double>.filled(count, 0);
    int j = 1;

    for (int i = 0; i < count; i++) {
      final t = firstMs + i * stepMs;

      while (j < localTimes.length - 1 && localTimes[j] < t) {
        j++;
      }

      final t0 = localTimes[j - 1].toDouble();
      final t1 = localTimes[j].toDouble();

      final v0 = localValues[j - 1];
      final v1 = localValues[j];

      if (t1 <= t0) {
        result[i] = v1;
      } else {
        final ratio = (t - t0) / (t1 - t0);
        final alpha = min(1.0, max(0.0, ratio));
        result[i] = v0 + (v1 - v0) * alpha;
      }
    }

    return result;
  }

  List<double> _buildFilteredSignal(List<double> raw, double fs) {
    final shortWindow = _oddWindow(0.18, fs, 3, 9);
    final longWindow = _oddWindow(1.25, fs, 15, 41);

    final shortAvg = _movingAverageCentered(raw, shortWindow);
    final longAvg = _movingAverageCentered(raw, longWindow);

    return List<double>.generate(
      raw.length,
      (i) => shortAvg[i] - longAvg[i],
    );
  }

  int _oddWindow(double seconds, double fs, int minValue, int maxValue) {
    var w = (seconds * fs).round();

    if (w < minValue) w = minValue;
    if (w > maxValue) w = maxValue;
    if (w.isEven) w++;

    return w;
  }

  List<double> _movingAverageCentered(List<double> values, int window) {
    if (values.isEmpty) return [];

    final half = window ~/ 2;
    final prefix = List<double>.filled(values.length + 1, 0);

    for (int i = 0; i < values.length; i++) {
      prefix[i + 1] = prefix[i] + values[i];
    }

    return List<double>.generate(values.length, (i) {
      final from = max(0, i - half);
      final to = min(values.length, i + half + 1);

      return (prefix[to] - prefix[from]) / (to - from);
    });
  }

  int? _estimateBpmByPeaks(List<double> signal, double fs) {
    if (signal.length < fs * 8) return null;

    final minDistance = max(
      2,
      (fs * 60 / _maxAllowedBpm).ceil(),
    );

    final peaks = <int>[];

    for (int i = 1; i < signal.length - 1; i++) {
      final v = signal[i];

      if (v < 0.35) continue;

      final isPeak = v > signal[i - 1] && v >= signal[i + 1];
      if (!isPeak) continue;

      if (peaks.isEmpty || i - peaks.last >= minDistance) {
        peaks.add(i);
      } else if (v > signal[peaks.last]) {
        peaks[peaks.length - 1] = i;
      }
    }

    if (peaks.length < 4) return null;

    final intervals = <int>[];

    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }

    intervals.sort();

    final medianInterval = intervals[intervals.length ~/ 2];
    if (medianInterval <= 0) return null;

    final bpm = (60 * fs / medianInterval).round();

    if (bpm < _minAllowedBpm || bpm > _maxAllowedBpm) return null;

    return bpm;
  }

  int? _acceptBpmEstimate(int estimate) {
    if (estimate < _minAllowedBpm || estimate > _maxAllowedBpm) {
      return null;
    }

    if (_lastAcceptedBpm == null) {
      _lastAcceptedBpm = estimate;
      return estimate;
    }

    final diff = (estimate - _lastAcceptedBpm!).abs();

    // Khi đã có lịch sử ổn định, không cho nhảy quá mạnh.
    if (_bpmHistory.length >= 3 && diff > 16) {
      return null;
    }

    // Lúc mới đo cũng không cho nhảy quá xa.
    if (_bpmHistory.length < 3 && diff > 24) {
      return null;
    }

    _lastAcceptedBpm = estimate;
    return estimate;
  }

  int _stableBpmFromHistory() {
    if (_bpmHistory.isEmpty) return 0;

    final recent = _bpmHistory.length <= 8
        ? List<int>.from(_bpmHistory)
        : _bpmHistory.sublist(_bpmHistory.length - 8);

    final sorted = List<int>.from(recent)..sort();
    final median = sorted[sorted.length ~/ 2];

    final filtered = recent.where((bpm) {
      return (bpm - median).abs() <= 8;
    }).toList();

    if (filtered.isEmpty) return median;

    final avg = filtered.reduce((a, b) => a + b) / filtered.length;

    return avg.round();
  }

  String _analyzeHeartRate() {
    if (_bpm < 60) return 'Thấp';
    if (_bpm > 100) return 'Cao';
    return 'Bình thường';
  }

  Color _getAnalysisColor() {
    if (_bpm < 60) return Colors.blue;
    if (_bpm > 100) return Colors.orange;
    return Colors.green;
  }

  String _getAnalysisDescription() {
    if (_bpm < 60) {
      return 'Nhịp tim thấp có thể do tập thể dục\nhoặc dùng thuốc. Nếu kèm\nchóng mặt, mờ mắt, cần khám bác sĩ.';
    }
    if (_bpm > 100) {
      return 'Nhịp tim nhanh có thể do stress,\n caffeine, hoặc bệnh lý tim.\nNghỉ ngơi và theo dõi.';
    }
    return 'Nhịp tim bình thường.\nDuy trì lối sống lành mạnh\nđể giữ tim khỏe mạnh.';
  }

  Widget _buildAnalysisCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAnalysisColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getAnalysisColor().withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAnalysisColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _bpm < 60
                  ? Icons.arrow_downward
                  : _bpm > 100
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
              color: _getAnalysisColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analyzeHeartRate(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getAnalysisColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAnalysisDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast(String text) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 450),
            tween: Tween(begin: -120.0, end: 40.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Positioned(
                top: value,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2DBB7A),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Color(0xFF2DBB7A),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      overlay.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 2), () {
        overlayEntry.remove();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), backgroundColor: Colors.green.shade700),
        );
      }
    }
  }

  Future<void> _saveHeartRate() async {
    if (_bpm <= 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final key = 'heart_rate_${now.year}_${now.month}_${now.day}';

      await prefs.setInt(key, _bpm);
      await prefs.setString('${key}_time', now.toIso8601String());

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_data')
            .doc('heart_rate')
            .collection('records')
            .add({
          'bpm': _bpm,
          'status': _analyzeHeartRate(),
          'timestamp': now,
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'hour': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        });
      }

      if (mounted) {
        _showSuccessToast('Đã lưu: $_bpm BPM - ${_analyzeHeartRate()}');
      }
    } catch (e) {
      debugPrint('Save heart rate error: $e');
    }
  }

  Future<void> _reset() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    _pulseController.stop();
    _waveController.stop();
    _clearSignalData(resetProgress: true);

    if (mounted) {
      setState(() {
        _bpm = 0;
        _countdown = 3;
        _isCountingDown = false;
        _isMeasuring = false;
        _isSignalPaused = false;
        _hasShownResult = false;
        _fingerOnCamera = false;
        _stableFingerFrames = 0;
        _status = 'Đặt ngón tay che kín camera sau';
      });
    }

    await _startFingerDetection();
  }

  Color _getStatusColor() {
    if (_hasShownResult) return Colors.green;
    if (_isSignalPaused) return Colors.orange;
    if (_isCountingDown) return Colors.greenAccent;
    if (_isMeasuring) return _fingerOnCamera ? Colors.blue : Colors.orange;
    return _fingerOnCamera ? Colors.greenAccent : Colors.orange;
  }

  String _instructionText() {
    if (_hasShownResult) {
      return 'Nhấn Lưu để lưu kết quả\nHoặc chọn Đo lại để thực hiện lần đo mới';
    }

    if (_isMeasuring && _isSignalPaused) {
      return 'Tiến trình đang tạm dừng vì mất tín hiệu\nĐặt lại ngón tay đúng vị trí để tiếp tục\nKhông cần đo lại từ đầu';
    }

    if (_isMeasuring) {
      return 'Đang đo nhịp tim\nGiữ yên ngón tay, không đè quá mạnh\nThanh phần trăm chỉ tăng khi tín hiệu hợp lệ';
    }

    if (_isCountingDown) {
      return 'Đúng vị trí\nGiữ nguyên ngón tay cho đến khi bắt đầu đo';
    }

    return 'Đặt ngón tay che kín camera sau\nHệ thống chỉ đo khi phát hiện đúng vị trí\nNếu sai vị trí, phép đo sẽ không bắt đầu';
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;

    if (!_isInitialized || controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return Container(color: Colors.black);
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildStateBadge() {
    IconData icon;
    String label;

    if (_isMeasuring) {
      icon = _isSignalPaused ? Icons.pause : Icons.graphic_eq;
      label = '${(_measurementProgress * 100).clamp(0, 100).round()}%';
    } else if (_isCountingDown) {
      icon = Icons.hourglass_top;
      label = '$_countdown';
    } else if (_isCameraStreaming && !_hasShownResult) {
      icon = Icons.camera_alt;
      label = 'Đang kiểm tra';
    } else if (_hasShownResult) {
      icon = Icons.check_circle;
      label = 'Hoàn tất';
    } else {
      icon = Icons.camera_alt;
      label = 'Camera';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    if (_isCountingDown) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.18),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.65),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 64,
                  height: 1,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sắp bắt đầu đo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (_isMeasuring || _hasShownResult) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isMeasuring && !_isSignalPaused ? _pulseAnimation.value : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.18),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _isSignalPaused ? Icons.pause : Icons.favorite,
                    color: _isSignalPaused ? Colors.orange : Colors.red,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _bpm > 0 ? '$_bpm' : '--',
                  style: const TextStyle(
                    fontSize: 82,
                    height: 0.95,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.5,
            ),
          ),
          child: Icon(
            _fingerOnCamera ? Icons.check_circle : Icons.touch_app,
            color: _fingerOnCamera ? Colors.greenAccent : Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _fingerOnCamera ? 'Đúng vị trí' : 'Đặt ngón tay lên camera',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    if (!_isMeasuring && !_hasShownResult) {
      return const SizedBox.shrink();
    }

    final percent = (_measurementProgress * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSignalPaused ? 'Tạm dừng' : 'Tiến trình đo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: _isSignalPaused ? Colors.orange : Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: _measurementProgress.clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isSignalPaused ? Colors.orange : Colors.greenAccent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_hasShownResult) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnalysisCard(),
        ],
      );
    }

    return const SizedBox(height: 58);
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveHeartRate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Lưu',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton(
      onPressed: () => _reset(),
      child: const Text(
        'Đo lại',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.25),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();

    _pulseController.dispose();
    _waveController.dispose();

    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isInitialized && controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((e) {
          debugPrint('Dispose stop stream error: $e');
        });
      }

      if (controller.value.isInitialized) {
        controller.setFlashMode(FlashMode.off).catchError((e) {
          debugPrint('Dispose flash off error: $e');
        });
      }

      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCameraPreview()),

          if (_isInitialized)
            Positioned.fill(
              child: Container(
                color: Colors.red.withOpacity(0.05),
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.78),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.24, 0.62, 1.0],
                ),
              ),
            ),
          ),

          if (_isMeasuring)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaveformPainter(
                      data: List<double>.from(_waveData),
                      phase: _waveController.value,
                      isActive: !_isSignalPaused,
                    ),
                  );
                },
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _topIconButton(
                        icon: Icons.close,
                        onTap: () async {
                          await _stopCameraProcessing(turnOffFlash: true);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      _buildStateBadge(),
                    ],
                  ),
                ),

                const Spacer(),

                _buildCenterContent(),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.28),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildProgressBar(),

                const SizedBox(height: 20),

                _buildBottomAction(),

                const SizedBox(height: 22),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    _instructionText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PpgFrameSample {
  final double value;
  final double mean;
  final double stdDev;
  final double? redRatio;

  const _PpgFrameSample({
    required this.value,
    required this.mean,
    required this.stdDev,
    this.redRatio,
  });
}

class WaveformPainter extends CustomPainter {
  final List<double> data;
  final double phase;
  final bool isActive;

  WaveformPainter({
    required this.data,
    required this.phase,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isActive ? Colors.red : Colors.orange).withOpacity(0.38)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height * 0.52;
    final amplitude = size.height * 0.055;

    if (data.length < 4) {
      _paintIdleWave(path, size, centerY, amplitude);
      canvas.drawPath(path, paint);
      return;
    }

    final smoothData = _smooth(data);
    final maxVal = smoothData.reduce((a, b) => a > b ? a : b);
    final minVal = smoothData.reduce((a, b) => a < b ? a : b);
    final range = max(0.0001, maxVal - minVal);
    final step = size.width / max(1, smoothData.length - 1);

    for (int i = 0; i < smoothData.length; i++) {
      final normalized = (smoothData[i] - minVal) / range;
      final x = i * step;
      final y = centerY - ((normalized - 0.5) * amplitude * 2.8);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _paintIdleWave(Path path, Size size, double centerY, double amplitude) {
    const points = 90;
    final phaseRad = phase * 2 * pi;

    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      final x = t * size.width;
      final wave = sin((t * 4.2 * pi) - phaseRad) * 0.65 +
          sin((t * 9.0 * pi) - phaseRad * 1.35) * 0.25;
      final y = centerY + wave * amplitude;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
  }

  List<double> _smooth(List<double> input) {
    if (input.length < 5) return input;

    final output = List<double>.filled(input.length, 0);

    for (int i = 0; i < input.length; i++) {
      final from = max(0, i - 2);
      final to = min(input.length, i + 3);

      double sum = 0;
      for (int j = from; j < to; j++) {
        sum += input[j];
      }

      output[i] = sum / (to - from);
    }

    return output;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isActive != isActive ||
        oldDelegate.data.length != data.length ||
        oldDelegate.data != data;
  }
}

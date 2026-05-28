import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({Key? key}) : super(key: key);

  static const List<MeditationTrack> tracks = [
    MeditationTrack(
      key: 'morning',
      title: 'Morning Relaxation',
      subtitle: 'Soft morning calm',
      audioAsset: 'audio/ambient/piano.mp3',
      backgroundAsset: 'assets/images/meditation/morning_relaxation.jpg',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFF5F8F),
      secondColor: Color(0xFFFF7D57),
      backgroundType: AmbientBackgroundType.forestBeach,
      defaultMixerKeys: ['birds'],
    ),
    MeditationTrack(
      key: 'heaven_water',
      title: 'Heaven Water',
      subtitle: 'Water and rain ambience',
      audioAsset: 'audio/ambient/rain.mp3',
      backgroundAsset: 'assets/images/meditation/1.jpg',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF32BCEC),
      secondColor: Color(0xFF50D3EF),
      backgroundType: AmbientBackgroundType.water,
      defaultMixerKeys: ['stream'],
    ),
    MeditationTrack(
      key: 'dreamer',
      title: 'Dreamer',
      subtitle: 'Dreamy night atmosphere',
      audioAsset: 'audio/ambient/night.mp3',
      backgroundAsset: 'assets/images/meditation/dreamer.jpg',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF008BA3),
      secondColor: Color(0xFF007295),
      backgroundType: AmbientBackgroundType.night,
      isPremium: true,
      defaultMixerKeys: ['wind'],
    ),
    MeditationTrack(
      key: 'om_chanting',
      title: 'Om Chanting',
      subtitle: 'Deep spiritual relax',
      audioAsset: 'audio/ambient/piano.mp3',
      backgroundAsset: 'assets/images/meditation/om_chanting.jpg',
      icon: Icons.spa_outlined,
      color: Color(0xFF8D65C5),
      secondColor: Color(0xFF7B4EB0),
      backgroundType: AmbientBackgroundType.mountain,
      defaultMixerKeys: ['flute'],
    ),
    MeditationTrack(
      key: 'deep_sleep',
      title: 'Deep Sleep',
      subtitle: 'Sleep and calm mind',
      audioAsset: 'audio/ambient/night.mp3',
      backgroundAsset: 'assets/images/meditation/deep_sleep.jpg',
      icon: Icons.nightlight_round,
      color: Color(0xFF6658DA),
      secondColor: Color(0xFF5148C8),
      backgroundType: AmbientBackgroundType.night,
      isPremium: true,
      defaultMixerKeys: ['crickets'],
    ),
    MeditationTrack(
      key: 'peaceful',
      title: 'Peaceful',
      subtitle: 'Peaceful forest air',
      audioAsset: 'audio/ambient/forest.mp3',
      backgroundAsset: 'assets/images/meditation/peaceful_forest.jpg',
      icon: Icons.filter_vintage_rounded,
      color: Color(0xFF36B78B),
      secondColor: Color(0xFF2EA87E),
      backgroundType: AmbientBackgroundType.forest,
      defaultMixerKeys: ['birds'],
    ),
    MeditationTrack(
      key: 'endless_sea',
      title: 'Endless Sea',
      subtitle: 'Ocean waves and sunset',
      audioAsset: 'audio/ambient/ocean.mp3',
      backgroundAsset: 'assets/images/meditation/endless_sea.jpg',
      icon: Icons.waves_rounded,
      color: Color(0xFFE3836D),
      secondColor: Color(0xFF5E526B),
      backgroundType: AmbientBackgroundType.ocean,
      isPremium: true,
      defaultMixerKeys: ['waves'],
    ),
  ];

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  static const String _soundKeyPref = 'meditation_sound_key';

  final List<MeditationTrack> _tracks = MeditationScreen.tracks;

  String _selectedTrackKey = 'morning';
  bool _loading = true;

  MeditationTrack get _selectedTrack {
    return _tracks.firstWhere(
      (track) => track.key == _selectedTrackKey,
      orElse: () => _tracks.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSelectedTrack();
  }

  Future<void> _loadSelectedTrack() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_soundKeyPref) ?? 'morning';

    if (!mounted) return;

    setState(() {
      _selectedTrackKey = _tracks.any((track) => track.key == savedKey)
          ? savedKey
          : 'morning';
      _loading = false;
    });
  }

  Future<void> _saveSelectedTrack(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKeyPref, key);

    if (!mounted) return;

    setState(() {
      _selectedTrackKey = key;
    });
  }

  void _openTrack(MeditationTrack track) {
    _saveSelectedTrack(track.key);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RelaxSoundPlayerScreen(
          track: track,
          mixerLibrary: MeditationMixerData.library,
        ),
      ),
    ).then((_) => _loadSelectedTrack());
  }

  Future<void> _openReminderSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeditationReminderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        leadingWidth: 64,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        title: const Text(
          'Meditation Music',
          style: TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openReminderSettings,
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
        itemCount: _tracks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final track = _tracks[index];

          return _MeditationMusicTile(
            track: track,
            large: false,
            selected: track.key == _selectedTrack.key,
            onTap: () => _openTrack(track),
          );
        },
      ),
    );
  }
}

class RelaxSoundPlayerScreen extends StatefulWidget {
  final MeditationTrack track;
  final List<MixerSoundItem> mixerLibrary;

  const RelaxSoundPlayerScreen({
    Key? key,
    required this.track,
    required this.mixerLibrary,
  }) : super(key: key);

  @override
  State<RelaxSoundPlayerScreen> createState() => _RelaxSoundPlayerScreenState();
}

class _RelaxSoundPlayerScreenState extends State<RelaxSoundPlayerScreen>
    with SingleTickerProviderStateMixin {
  static const String _systemVolumePref = 'relax_system_volume';
  static const String _timerMinutesPref = 'relax_timer_minutes';

  static const Color _orange = Color(0xFFFF8634);

  final AudioPlayer _basePlayer = AudioPlayer();
  final Map<String, AudioPlayer> _mixerPlayers = {};

  late final AnimationController _backgroundController;
  late final List<ActiveMixerSound> _activeSounds;

  Timer? _timer;
  bool _isPlaying = true;
  bool _baseStarted = false;

  double _systemVolume = 0.86;
  int _totalSeconds = 5 * 60;
  int _remainingSeconds = 5 * 60;

  double get _progress {
    if (_totalSeconds <= 0) return 0;
    return ((_totalSeconds - _remainingSeconds) / _totalSeconds).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();

    _activeSounds = _createDefaultActiveSounds();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _enableFullscreen();
    _loadSessionSettings();
    _playAll();
    _startTimerTicker();
  }

  List<ActiveMixerSound> _createDefaultActiveSounds() {
    final result = <ActiveMixerSound>[];

    for (final key in widget.track.defaultMixerKeys) {
      final item = _findMixerItem(key);
      if (item != null) {
        result.add(ActiveMixerSound(item: item, volume: item.defaultVolume));
      }
    }

    if (result.isEmpty) {
      final birds = _findMixerItem('birds') ?? widget.mixerLibrary.first;
      result.add(ActiveMixerSound(item: birds, volume: birds.defaultVolume));
    }

    return result;
  }

  MixerSoundItem? _findMixerItem(String key) {
    for (final item in widget.mixerLibrary) {
      if (item.key == key) return item;
    }

    return null;
  }

  Future<void> _loadSessionSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final savedSeconds = prefs.getInt(_timerMinutesPref) ?? 300;
    final systemVolume = prefs.getDouble(_systemVolumePref) ?? 0.86;

    if (!mounted) return;

    setState(() {
      _systemVolume = systemVolume.clamp(0.0, 1.0);
      _totalSeconds = savedSeconds;
      _remainingSeconds = min(_remainingSeconds, _totalSeconds);
      if (_remainingSeconds <= 0) {
        _remainingSeconds = _totalSeconds;
      }
    });

    await _syncAllVolumes();
  }

  Future<void> _saveSessionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_systemVolumePref, _systemVolume);
    await prefs.setInt(_timerMinutesPref, _totalSeconds);
  }

  Future<void> _enableFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _basePlayer.dispose();

    for (final player in _mixerPlayers.values) {
      player.dispose();
    }

    _backgroundController.dispose();
    _restoreSystemUi();

    super.dispose();
  }

  Future<void> _playAll() async {
    setState(() {
      _isPlaying = true;
    });

    _backgroundController.repeat();
    await _playBaseTrack();

    for (final activeSound in _activeSounds) {
      await _ensureMixerSoundPlaying(activeSound);
    }

    _startTimerTicker();
  }

  Future<void> _pauseAll() async {
    _timer?.cancel();

    setState(() {
      _isPlaying = false;
    });

    _backgroundController.stop(canceled: false);

    try {
      await _basePlayer.pause();

      for (final player in _mixerPlayers.values) {
        await player.pause();
      }
    } catch (error) {
      debugPrint('Pause audio error: $error');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pauseAll();
    } else {
      await _playAll();
    }
  }

  Future<void> _playBaseTrack() async {
    try {
      await _basePlayer.setReleaseMode(ReleaseMode.loop);
      await _basePlayer.setVolume(_systemVolume);

      if (_baseStarted) {
        await _basePlayer.resume();
      } else {
        await _basePlayer.play(AssetSource(widget.track.audioAsset));
        _baseStarted = true;
      }
    } catch (error) {
      debugPrint('Play base track error: $error');
    }
  }

  Future<void> _ensureMixerSoundPlaying(ActiveMixerSound activeSound) async {
    try {
      final player = _mixerPlayers.putIfAbsent(
        activeSound.item.key,
        () => AudioPlayer(),
      );

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(_volumeFor(activeSound));

      if (player.state == PlayerState.paused) {
        await player.resume();
        return;
      }

      if (player.state != PlayerState.playing) {
        await player.play(AssetSource(activeSound.item.assetPath));
      }
    } catch (error) {
      debugPrint('Play mixer sound error: $error');
    }
  }

  double _volumeFor(ActiveMixerSound activeSound) {
    return (activeSound.volume * _systemVolume).clamp(0.0, 1.0);
  }

  Future<void> _syncAllVolumes() async {
    try {
      await _basePlayer.setVolume(_systemVolume);

      for (final activeSound in _activeSounds) {
        final player = _mixerPlayers[activeSound.item.key];
        if (player != null) {
          await player.setVolume(_volumeFor(activeSound));
        }
      }
    } catch (error) {
      debugPrint('Sync volume error: $error');
    }
  }

  void _startTimerTicker() {
    _timer?.cancel();

    if (!_isPlaying) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPlaying) return;

      if (_remainingSeconds <= 1) {
        _completeSession();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();

    final minutesMeditated = (_totalSeconds - _remainingSeconds) ~/ 60;
    final wasPaused = !_isPlaying;

    setState(() {
      _remainingSeconds = _totalSeconds;
      _isPlaying = false;
    });

    try {
      await _basePlayer.pause();

      for (final player in _mixerPlayers.values) {
        await player.pause();
      }
    } catch (error) {
      debugPrint('Complete session audio error: $error');
    }

    if (!mounted) return;

    // Tính EXP
    await _calculateAndAddExp(minutesMeditated, wasPaused);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🧘', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Meditation completed! +10 XP'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Add XP for meditation
    if (minutesMeditated >= 5) {
      TreeService().addMeditationXp();
    }
  }

  Future<void> _calculateAndAddExp(int minutes, bool wasPaused) async {
    if (minutes < 1) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // EXP cơ bản: 80 EXP/phút
    int expEarned = minutes * 80;

    // Bonus: Không pause
    if (!wasPaused) {
      expEarned += (minutes * 20); // +20 EXP/phút
    }

    // Bonus: Premium sound (isPremium)
    if (widget.track.isPremium) {
      expEarned += (minutes * 30);
    }

    // Kiểm tra streak
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userData = userDoc.data() ?? {};
    int currentStreak = userData['meditationStreak'] ?? 0;
    int currentExp = userData['meditationExp'] ?? 0;
    int currentMinutes = userData['meditationMinutes'] ?? 0;
    int currentLevel = userData['mindLevel'] ?? 1;
    DateTime? lastDate = userData['lastMeditationDate'] != null
        ? (userData['lastMeditationDate'] as Timestamp).toDate()
        : null;

    // Kiểm tra streak (thiền liên tiếp)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastDate != null) {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      
      if (diff == 1) {
        currentStreak++;
        expEarned += (currentStreak * 50); // Bonus streak
      } else if (diff > 1) {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    // Tính level mới (500 EXP mỗi level)
    final newExp = currentExp + expEarned;
    final newLevel = (newExp ~/ 500) + 1;
    final leveledUp = newLevel > currentLevel;

    // Cập nhật lên Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'meditationExp': newExp,
      'meditationMinutes': currentMinutes + minutes,
      'meditationStreak': currentStreak,
      'mindLevel': newLevel,
      'lastMeditationDate': DateTime.now(),
    });

    // Hiển thị thông báo
    if (!mounted) return;

    String message = '+$expEarned EXP';
    if (leveledUp) {
      message += ' | Mind Level $newLevel!';
    }
    if (currentStreak > 1) {
      message += ' | $currentStreak Day Streak';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _setTimerSeconds(int seconds) async {
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = _totalSeconds;
    });

    await _saveSessionSettings();

    if (_isPlaying) {
      _startTimerTicker();
    }
  }

  Future<void> _changeSystemVolume(double value) async {
    setState(() {
      _systemVolume = value.clamp(0.0, 1.0);
    });

    await _saveSessionSettings();
    await _syncAllVolumes();
  }

  Future<void> _changeActiveVolume(String key, double value) async {
    final index = _activeSounds.indexWhere((sound) => sound.item.key == key);
    if (index < 0) return;

    setState(() {
      _activeSounds[index] = _activeSounds[index].copyWith(
        volume: value.clamp(0.0, 1.0),
      );
    });

    await _syncAllVolumes();
  }

  Future<void> _addMixerSound(MixerSoundItem item) async {
    final alreadyActive = _activeSounds.any((sound) => sound.item.key == item.key);
    if (alreadyActive) return;

    final newSound = ActiveMixerSound(item: item, volume: 1.0);

    setState(() {
      _activeSounds.add(newSound);
    });

    if (_isPlaying) {
      await _ensureMixerSoundPlaying(newSound);
      await _syncAllVolumes();
    }
  }

  Future<void> _removeMixerSound(String key) async {
    setState(() {
      _activeSounds.removeWhere((sound) => sound.item.key == key);
    });

    final player = _mixerPlayers.remove(key);

    try {
      await player?.stop();
      await player?.dispose();
    } catch (error) {
      debugPrint('Remove mixer sound error: $error');
    }

    // Nếu không còn hiệu ứng nào, phát lại âm gốc của track
    if (_activeSounds.isEmpty && _isPlaying) {
      await _basePlayer.stop();
      _baseStarted = false;
      try {
        await _basePlayer.setReleaseMode(ReleaseMode.loop);
        await _basePlayer.setVolume(_systemVolume);
        await _basePlayer.play(AssetSource(widget.track.audioAsset));
        _baseStarted = true;
      } catch (error) {
        debugPrint('Restore track audio error: $error');
      }
    }
  }

  String _formatRemainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _openTimerDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (dialogContext) {
        final options = [30, 60, 120, 300, 600, 900, 1800, 3600];

        String formatOption(int seconds) {
          if (seconds < 60) return '${seconds}s';
          final min = seconds ~/ 60;
          final sec = seconds % 60;
          if (sec == 0) return '${min} min';
          return '$min min ${sec}s';
        }

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Timer',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: options.map((seconds) {
                      final selected = _totalSeconds == seconds;

                      return ChoiceChip(
                        selected: selected,
                        selectedColor: _orange,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected ? _orange : Colors.black.withOpacity(0.15),
                        ),
                        label: Text(
                          formatOption(seconds),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onSelected: (_) async {
                          Navigator.pop(dialogContext);
                          await _setTimerSeconds(seconds);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Remaining: ${_formatRemainingTime()}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMixerDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width - 38,
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          await _openAddSoundDialog();
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Row(
                          children: [
                            Container(
                              height: 64,
                              width: 64,
                              decoration: const BoxDecoration(
                                color: _orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Expanded(
                              child: Text(
                                'Add a New Sound',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_activeSounds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'No active sound. Tap + to add one.',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        ..._activeSounds.map((activeSound) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _MixerVolumeRow(
                              activeSound: activeSound,
                              orange: _orange,
                              onChanged: (value) async {
                                modalSetState(() {});
                                await _changeActiveVolume(activeSound.item.key, value);
                              },
                              onDelete: () async {
                                await _removeMixerSound(activeSound.item.key);
                                modalSetState(() {});
                              },
                            ),
                          );
                        }),
                      Divider(
                        color: Colors.black.withOpacity(0.45),
                        thickness: 1,
                        height: 28,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'System Volume',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.9),
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _orange,
                                inactiveTrackColor: const Color(0xFFE1E1E1),
                                thumbColor: _orange,
                                overlayColor: _orange.withOpacity(0.12),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _systemVolume,
                                min: 0,
                                max: 1,
                                onChanged: (value) async {
                                  await _changeSystemVolume(value);
                                  modalSetState(() {});
                                },
                              ),
                            ),
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
      },
    );
  }

  Future<void> _openAddSoundDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 38,
              padding: const EdgeInsets.fromLTRB(34, 38, 34, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SoundCategorySection(
                      title: 'Music',
                      sounds: _soundsByCategory(MixerCategory.music),
                      orange: _orange,
                      onTapSound: (item) async {
                        await _addMixerSound(item);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        await _openMixerDialog();
                      },
                    ),
                    const SizedBox(height: 28),
                    _SoundCategorySection(
                      title: 'Nature',
                      sounds: _soundsByCategory(MixerCategory.nature),
                      orange: _orange,
                      onTapSound: (item) async {
                        await _addMixerSound(item);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        await _openMixerDialog();
                      },
                    ),
                    const SizedBox(height: 28),
                    _SoundCategorySection(
                      title: 'Animals',
                      sounds: _soundsByCategory(MixerCategory.animals),
                      orange: _orange,
                      onTapSound: (item) async {
                        await _addMixerSound(item);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        await _openMixerDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<MixerSoundItem> _soundsByCategory(MixerCategory category) {
    return widget.mixerLibrary
        .where((item) => item.category == category)
        .toList(growable: false);
  }

  double _scaleRange(AmbientBackgroundType type) {
    switch (type) {
      case AmbientBackgroundType.night:
        return 0.012;
      case AmbientBackgroundType.mountain:
        return 0.018;
      case AmbientBackgroundType.water:
        return 0.022;
      case AmbientBackgroundType.ocean:
      case AmbientBackgroundType.forestBeach:
        return 0.02;
      case AmbientBackgroundType.forest:
        return 0.018;
      default:
        return 0.025;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          final raw = _backgroundController.value;
          final eased = Curves.easeInOutSine.transform(raw);
          final breathPhase = eased * 2 * pi;
          final breathValue = sin(breathPhase);
          final type = widget.track.backgroundType;

          final scale = _isPlaying
              ? 1.0 + _scaleRange(type) * (0.5 + breathValue * 0.5)
              : 1.015;

          return Stack(
            children: [
              Positioned.fill(
                child: Transform.scale(
                  scale: scale,
                  child: _CinematicBackground(
                    track: widget.track,
                    breathValue: breathValue,
                    isPlaying: _isPlaying,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.32 + breathValue * 0.04),
                        Colors.black.withOpacity(0.06),
                        Colors.black.withOpacity(0.16 + breathValue * 0.03),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 76),
                    _buildActiveSoundButtons(),
                    const Spacer(),
                    _buildMainControls(),
                    const SizedBox(height: 22),
                    _buildProgressSlider(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 68),
              child: Text(
                widget.track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSoundButtons() {
    const double spacing = 24;
    const double itemSize = 90;
    final allItems = _activeSounds.toList();
    final tiles = <Widget>[];

    for (final s in allItems) {
      tiles.add(_RoundSoundButton(
        item: s.item,
        size: 72,
        orange: _orange,
        showBadge: true,
        onTap: _openMixerDialog,
      ));
    }

    if (allItems.length < 6) {
      tiles.add(GestureDetector(
        onTap: _openAddSoundDialog,
        child: SizedBox(
          height: itemSize,
          width: itemSize,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ));
    }

    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 3) {
      final rowTiles = tiles.sublist(i, (i + 3).clamp(0, tiles.length));
      final row = <Widget>[];
      for (int j = 0; j < rowTiles.length; j++) {
        if (j > 0) row.add(SizedBox(width: spacing));
        row.add(rowTiles[j]);
      }
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: row,
      ));
      if (i + 3 < tiles.length) {
        rows.add(const SizedBox(height: 18));
      }
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: _orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 54),
        GestureDetector(
          onTap: _openTimerDialog,
          child: Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFF101425),
                  size: 20,
                ),
                Positioned(
                  bottom: 8,
                  child: Text(
                    _formatRemainingTime(),
                    style: TextStyle(
                      color: const Color(0xFF101425).withOpacity(0.82),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: _orange,
          inactiveTrackColor: Colors.white.withOpacity(0.28),
          thumbColor: _orange,
          overlayColor: _orange.withOpacity(0.12),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(
          value: _systemVolume,
          min: 0,
          max: 1,
          onChanged: (value) {
            _changeSystemVolume(value);
          },
        ),
      ),
    );
  }
}

class _MeditationMusicTile extends StatelessWidget {
  final MeditationTrack track;
  final bool large;
  final bool selected;
  final VoidCallback onTap;

  const _MeditationMusicTile({
    required this.track,
    required this.large,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = large ? 24.0 : 18.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: large ? 142 : 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              track.color,
              track.secondColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: track.color.withOpacity(selected ? 0.34 : 0.20),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MusicTileLandscapePainter(
                    track: track,
                    large: large,
                  ),
                ),
              ),
              if (large)
                Positioned(
                  right: 142,
                  top: 30,
                  child: Icon(
                    track.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              Positioned(
                left: large ? 24 : 22,
                top: large ? 22 : 0,
                bottom: large ? null : 0,
                right: large ? 20 : 90,
                child: Row(
                  children: [
                    if (!large) ...[
                      Icon(
                        track.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: large ? 28 : 25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (track.isPremium)
                Positioned(
                  right: 19,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundSoundButton extends StatelessWidget {
  final MixerSoundItem item;
  final double size;
  final Color orange;
  final bool showBadge;
  final VoidCallback onTap;

  const _RoundSoundButton({
    required this.item,
    required this.size,
    required this.orange,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = item.badgeText;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: size + 18,
        width: size + 18,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: size * 0.38,
                ),
              ),
            ),
            if (showBadge && badge != null)
              Positioned(
                left: 2,
                top: 0,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MixerVolumeRow extends StatelessWidget {
  final ActiveMixerSound activeSound;
  final Color orange;
  final ValueChanged<double> onChanged;
  final VoidCallback onDelete;

  const _MixerVolumeRow({
    required this.activeSound,
    required this.orange,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MixerCircleIcon(
          item: activeSound.item,
          orange: orange,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: orange,
              inactiveTrackColor: const Color(0xFFE1E1E1),
              thumbColor: orange,
              overlayColor: orange.withOpacity(0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: activeSound.volume,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_rounded,
            color: Color(0xFF606060),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _MixerCircleIcon extends StatelessWidget {
  final MixerSoundItem item;
  final Color orange;

  const _MixerCircleIcon({
    required this.item,
    required this.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: orange,
          width: 3,
        ),
      ),
      child: Icon(
        item.icon,
        color: orange,
        size: 20,
      ),
    );
  }
}

class _SoundCategorySection extends StatelessWidget {
  final String title;
  final List<MixerSoundItem> sounds;
  final Color orange;
  final ValueChanged<MixerSoundItem> onTapSound;

  const _SoundCategorySection({
    required this.title,
    required this.sounds,
    required this.orange,
    required this.onTapSound,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 18,
          crossAxisSpacing: 17,
          childAspectRatio: 1,
          children: sounds.map((sound) {
            return GestureDetector(
              onTap: () => onTapSound(sound),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: orange,
                    width: 3,
                  ),
                ),
                child: Icon(
                  sound.icon,
                  color: orange,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CinematicBackground extends StatelessWidget {
  final MeditationTrack track;
  final double breathValue;
  final bool isPlaying;

  const _CinematicBackground({
    required this.track,
    required this.breathValue,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final type = track.backgroundType;
    final bv = isPlaying ? breathValue : 0.0;
    final normalizedBv = 0.5 + bv * 0.5;

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              track.backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return CustomPaint(
                  painter: _CinematicFallbackPainter(
                    track: track,
                    progress: normalizedBv,
                    isPlaying: isPlaying,
                  ),
                );
              },
            ),
          ),
          if (isPlaying)
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientEffectPainter(
                  color: track.color,
                  breathValue: bv,
                  backgroundType: type,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmbientEffectPainter extends CustomPainter {
  final Color color;
  final double breathValue;
  final AmbientBackgroundType backgroundType;

  _AmbientEffectPainter({
    required this.color,
    required this.breathValue,
    required this.backgroundType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bv = breathValue;
    final nbv = 0.5 + bv * 0.5;
    final type = backgroundType;

    // 1. Glow
    final glow = Paint()
      ..color = color.withOpacity(0.03 + nbv * 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(
      Offset(size.width * 0.7 + bv * 10, size.height * 0.2 + bv * 5),
      120 + nbv * 25,
      glow,
    );

    // 2. Particles
    _drawParticles(canvas, size, type, bv, nbv);

    // 3. Type-specific effects + fog
    switch (type) {
      case AmbientBackgroundType.water:
        _drawWaterShimmer(canvas, size, bv, nbv);
        _drawFog(canvas, size, bv, 0.025, const Color(0xFFC8E6F5));
        break;
      case AmbientBackgroundType.night:
        _drawFog(canvas, size, bv, 0.035, const Color(0xFFB8D4E3));
        break;
      case AmbientBackgroundType.mountain:
        _drawMountainParallax(canvas, size, bv);
        _drawFog(canvas, size, bv, 0.06, const Color(0xFFD4C9B3));
        break;
      case AmbientBackgroundType.forest:
        _drawForestRays(canvas, size, bv, nbv);
        _drawFog(canvas, size, bv, 0.04, const Color(0xFFC8E0C0));
        break;
      case AmbientBackgroundType.ocean:
      case AmbientBackgroundType.forestBeach:
        _drawFog(canvas, size, bv, 0.03, const Color(0xFFB8D4E3));
        break;
      default:
        break;
    }
  }

  void _drawParticles(Canvas canvas, Size size, AmbientBackgroundType type, double bv, double nbv) {
    final paint = Paint()..style = PaintingStyle.fill;
    final count = switch (type) {
      AmbientBackgroundType.night => 6,
      AmbientBackgroundType.water => 5,
      AmbientBackgroundType.mountain => 4,
      AmbientBackgroundType.forest => 6,
      _ => 8,
    };

    for (int i = 0; i < count; i++) {
      final x = ((i * 83 + 29) % size.width) + sin(bv * 0.5 * pi + i * 1.7) * 12;
      final yBase = switch (type) {
        AmbientBackgroundType.mountain => size.height * 0.7,
        AmbientBackgroundType.night => (i * 67 + 19) % (size.height * 0.5),
        _ => ((i * 53 + 11) % size.height).toDouble(),
      };
      final y = yBase + sin(bv * 0.4 * pi + i * 0.9) * 6 - nbv * 10;

      final alpha = switch (type) {
        AmbientBackgroundType.night => (0.06 + sin(bv * 1.5 * pi + i * 2.3) * 0.1).clamp(0.04, 0.2),
        AmbientBackgroundType.mountain => (0.02 + sin(bv * 0.6 * pi + i) * 0.015).clamp(0.005, 0.04),
        _ => (0.03 + nbv * 0.03).clamp(0.01, 0.07),
      };
      final r = switch (type) {
        AmbientBackgroundType.night => 1.0 + (0.6 + sin(bv * 1.5 * pi + i * 2.3) * 0.4) * 0.8,
        AmbientBackgroundType.mountain => 10 + nbv * 4,
        _ => 1.5 + nbv * 0.8,
      };

      final c = switch (type) {
        AmbientBackgroundType.mountain => const Color(0xFFD4C9B3),
        _ => Colors.white,
      };

      if (type == AmbientBackgroundType.mountain) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      } else {
        paint.maskFilter = null;
      }
      paint.color = c.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawWaterShimmer(Canvas canvas, Size size, double bv, double nbv) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.35 + i * 0.12)
        + sin(bv * pi + i * 1.5) * size.height * 0.015;
      paint
        ..color = Colors.white.withOpacity((0.02 + nbv * 0.03).clamp(0.01, 0.05))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + i * 4);

      final path = Path();
      path.moveTo(sin(bv * 0.8 * pi + i) * size.width * 0.04, y);
      for (double x = 0; x <= size.width; x += size.width / 25) {
        path.lineTo(x, y + sin(x * 0.03 + bv * 1.2 * pi + i) * 3);
      }
      path.lineTo(size.width, y + 6);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawMountainParallax(Canvas canvas, Size size, double bv) {
    final drift = bv * 4;
    for (int layer = 0; layer < 2; layer++) {
      final factor = layer == 0 ? 1.2 : 0.6;
      final opacity = layer == 0 ? 0.05 : 0.035;
      final yBase = layer == 0 ? 0.78 : 0.64;
      final hScale = layer == 0 ? 0.04 : 0.06;
      final paint = Paint()
        ..color = const Color(0xFF3D4A3C).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(-10, size.height);
      path.lineTo(-10, size.height * yBase + drift * factor * 0.5);
      for (double x = -10; x <= size.width + 10; x += size.width / 20) {
        path.lineTo(x, size.height * yBase
          + sin((x + drift * factor) * 0.02) * size.height * hScale
          + drift * factor * 0.5);
      }
      path.lineTo(size.width + 10, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawForestRays(Canvas canvas, Size size, double bv, double nbv) {
    final opacity = 0.015 + nbv * 0.02;
    for (int i = 0; i < 3; i++) {
      final xCenter = size.width * (0.2 + i * 0.3) + bv * 3;
      final ray = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF8E1).withOpacity(opacity),
            const Color(0xFFFFF8E1).withOpacity(0),
          ],
        ).createShader(Rect.fromCenter(
          center: Offset(xCenter, 0),
          width: 35 + nbv * 8,
          height: size.height * 0.6,
        ));

      canvas.save();
      canvas.translate(xCenter, 0);
      canvas.rotate((-0.06 + i * 0.04) + bv * 0.012);
      canvas.drawRect(
        Rect.fromLTWH(-18 - nbv * 4, 0, 35 + nbv * 8, size.height * 0.6),
        ray,
      );
      canvas.restore();
    }
  }

  void _drawFog(Canvas canvas, Size size, double bv, double baseOpacity, Color color) {
    final nbv = 0.5 + bv * 0.5;
    final opacity = baseOpacity + nbv * 0.015;

    final fog = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0),
          color.withOpacity(opacity * 0.3),
          color.withOpacity(opacity),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fog);

    final wave = Paint()
      ..color = color.withOpacity(opacity * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * (0.74 + bv * 0.02));
    for (double x = 0; x <= size.width; x += size.width / 30) {
      path.lineTo(x, size.height * (0.76
        + sin(x * 0.012 + bv * pi) * 0.02
        + sin(x * 0.025 + bv * 0.5 * pi) * 0.01));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, wave);
  }

  @override
  bool shouldRepaint(covariant _AmbientEffectPainter oldDelegate) {
    return oldDelegate.breathValue != breathValue
        || oldDelegate.color != color
        || oldDelegate.backgroundType != backgroundType;
  }
}

class _MusicTileLandscapePainter extends CustomPainter {
  final MeditationTrack track;
  final bool large;

  _MusicTileLandscapePainter({
    required this.track,
    required this.large,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final softPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.28),
      large ? 72 : 42,
      softPaint,
    );

    final mountainPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.48,
        size.width * 0.33,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.38,
        size.width * 0.76,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.54,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, mountainPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = large ? 2.4 : 1.5
      ..strokeCap = StrokeCap.round;

    if (large) {
      for (int i = 0; i < 36; i++) {
        final x = size.width * 0.25 + i * 8;
        final h = 12 + sin(i * 0.8) * 12;
        canvas.drawLine(
          Offset(x, size.height * 0.53 - h / 2),
          Offset(x, size.height * 0.53 + h / 2),
          linePaint,
        );
      }

      final leafPaint = Paint()
        ..color = Colors.white.withOpacity(0.14)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 24; i++) {
        final x = i * 26.0;
        final y = size.height - 20 - (i % 5) * 5;
        canvas.drawCircle(Offset(x, y), 16, leafPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MusicTileLandscapePainter oldDelegate) {
    return oldDelegate.track != track || oldDelegate.large != large;
  }
}

class _CinematicFallbackPainter extends CustomPainter {
  final MeditationTrack track;
  final double progress;
  final bool isPlaying;

  _CinematicFallbackPainter({
    required this.track,
    required this.progress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          track.color.withOpacity(0.82),
          track.secondColor.withOpacity(0.72),
          const Color(0xFF0B1D1F),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    switch (track.backgroundType) {
      case AmbientBackgroundType.ocean:
      case AmbientBackgroundType.forestBeach:
        _drawBeach(canvas, size);
        break;
      case AmbientBackgroundType.forest:
        _drawForest(canvas, size);
        break;
      case AmbientBackgroundType.water:
        _drawWater(canvas, size);
        break;
      case AmbientBackgroundType.night:
        _drawNight(canvas, size);
        break;
      case AmbientBackgroundType.mountain:
        _drawMountains(canvas, size);
        break;
      case AmbientBackgroundType.glow:
        _drawGlow(canvas, size);
        break;
    }
  }

  void _drawBeach(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = const Color(0xFF194C32).withOpacity(0.86)
      ..style = PaintingStyle.fill;

    final land = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.56)
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.52,
        size.width * 0.6,
        size.height * 0.75,
        0,
        size.height * 0.61,
      )
      ..close();

    canvas.drawPath(land, landPaint);

    final sandPaint = Paint()
      ..color = const Color(0xFFD8AA6D).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final sand = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.66,
        size.width * 0.70,
        size.height * 0.58,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(sand, sandPaint);

    final oceanPaint = Paint()
      ..color = const Color(0xFF09AFC3).withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final ocean = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.66,
        size.width * 0.66,
        size.height * 0.82,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(ocean, oceanPaint);
  }

  void _drawForest(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B4E35).withOpacity(0.92)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x = i * size.width / 14;
      final h = size.height * (0.28 + (i % 4) * 0.04);
      final tree = Path()
        ..moveTo(x, size.height * 0.78 - h)
        ..lineTo(x - 36, size.height * 0.78)
        ..lineTo(x + 36, size.height * 0.78)
        ..close();
      canvas.drawPath(tree, paint);
    }
  }

  void _drawWater(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 0; i < 7; i++) {
      final y = size.height * (0.42 + i * 0.065);
      final path = Path()..moveTo(0, y);

      for (double x = 0; x <= size.width; x += 12) {
        path.lineTo(
          x,
          y + sin(x / 34 + progress * pi * 2 + i) * 9,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawNight(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.62)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 42; i++) {
      final x = (i * 47) % size.width;
      final y = (i * 71) % (size.height * 0.65);
      final r = 1.0 + sin(progress * 2 * pi + i) * 0.9;
      canvas.drawCircle(Offset(x, y), r.abs(), paint);
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A2756).withOpacity(0.78)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width * 0.25, size.height * 0.34)
      ..lineTo(size.width * 0.46, size.height * 0.58)
      ..lineTo(size.width * 0.68, size.height * 0.30)
      ..lineTo(size.width, size.height * 0.64)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawGlow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.46),
      145 + sin(progress * pi * 2) * 28,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CinematicFallbackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.track != track ||
        oldDelegate.isPlaying != isPlaying;
  }
}

class MeditationReminderScreen extends StatefulWidget {
  const MeditationReminderScreen({Key? key}) : super(key: key);

  @override
  State<MeditationReminderScreen> createState() => _MeditationReminderScreenState();
}

class _MeditationReminderScreenState extends State<MeditationReminderScreen> {
  static const String _enabledPref = 'meditation_reminder_enabled';
  static const String _hourPref = 'meditation_reminder_hour';
  static const String _minutePref = 'meditation_reminder_minute';

  bool _enabled = true;
  bool _loading = true;
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _enabled = prefs.getBool(_enabledPref) ?? true;
      _time = TimeOfDay(
        hour: prefs.getInt(_hourPref) ?? 16,
        minute: prefs.getInt(_minutePref) ?? 0,
      );
      _loading = false;
    });
  }

  Future<void> _saveReminder() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledPref, _enabled);
    await prefs.setInt(_hourPref, _time.hour);
    await prefs.setInt(_minutePref, _time.minute);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _enabled
              ? 'Reminder saved at ${_formatTime(_time)}'
              : 'Reminder turned off',
        ),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8634),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _time = result;
      _enabled = true;
    });
  }

  void _quickSet(int hour, int minute) {
    setState(() {
      _time = TimeOfDay(hour: hour, minute: minute);
      _enabled = true;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F8),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Reminder',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFFF8634),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 82,
                    width: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8634).withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alarm_rounded,
                      color: Color(0xFFFF8634),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daily Relax Reminder',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhắc bạn nghe nhạc thư giãn mỗi ngày',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Text(
                      _formatTime(_time),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Change Time'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8634),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: SwitchListTile.adaptive(
                value: _enabled,
                activeColor: const Color(0xFFFF8634),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Enable reminder',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  _enabled
                      ? 'Reminder is active at ${_formatTime(_time)}'
                      : 'Reminder is turned off',
                ),
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quick set',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quickChip('07:00', 7, 0),
                _quickChip('12:00', 12, 0),
                _quickChip('16:00', 16, 0),
                _quickChip('22:00', 22, 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, int hour, int minute) {
    final selected = _time.hour == hour && _time.minute == minute;

    return ChoiceChip(
      selected: selected,
      selectedColor: const Color(0xFFFF8634),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? const Color(0xFFFF8634)
            : Colors.black.withOpacity(0.08),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
      onSelected: (_) => _quickSet(hour, minute),
    );
  }
}

class MeditationMixerData {
  static const List<MixerSoundItem> library = [
    MixerSoundItem(
      key: 'accordion',
      title: 'Accordion',
      category: MixerCategory.music,
      assetPath: 'audio/effects/rainbirt.mp3',
      icon: Icons.flutter_dash_rounded,
      defaultVolume: 0.55,
    ),
    MixerSoundItem(
      key: 'stone_bowl',
      title: 'Singing Bowl',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.trip_origin_rounded,
      defaultVolume: 0.55,
    ),
    MixerSoundItem(
      key: 'flute',
      title: 'Flute',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.edit_rounded,
      badgeText: '12',
      defaultVolume: 0.38,
    ),
    MixerSoundItem(
      key: 'pan_flute',
      title: 'Pan Flute',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.graphic_eq_rounded,
      defaultVolume: 0.44,
    ),
    MixerSoundItem(
      key: 'guitar',
      title: 'Guitar',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.music_note_rounded,
      defaultVolume: 0.5,
    ),
    MixerSoundItem(
      key: 'violin',
      title: 'Violin',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.audiotrack_rounded,
      defaultVolume: 0.48,
    ),
    MixerSoundItem(
      key: 'saxophone',
      title: 'Saxophone',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.library_music_rounded,
      defaultVolume: 0.48,
    ),
    MixerSoundItem(
      key: 'drum',
      title: 'Drum',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.album_rounded,
      defaultVolume: 0.42,
    ),
    MixerSoundItem(
      key: 'keyboard',
      title: 'Keyboard',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.piano_rounded,
      defaultVolume: 0.5,
    ),
    MixerSoundItem(
      key: 'piano',
      title: 'Piano',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.piano_rounded,
      defaultVolume: 0.58,
    ),
    MixerSoundItem(
      key: 'bells',
      title: 'Bells',
      category: MixerCategory.music,
      assetPath: 'audio/ambient/piano.mp3',
      icon: Icons.graphic_eq_rounded,
      defaultVolume: 0.48,
    ),
    MixerSoundItem(
      key: 'campfire',
      title: 'Campfire',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/campfire.mp3',
      icon: Icons.local_fire_department_rounded,
      defaultVolume: 0.55,
    ),
    MixerSoundItem(
      key: 'rain',
      title: 'Rain',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/rain.mp3',
      icon: Icons.water_drop_rounded,
      defaultVolume: 0.5,
    ),
    MixerSoundItem(
      key: 'storm',
      title: 'Storm',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/rain.mp3',
      icon: Icons.thunderstorm_rounded,
      defaultVolume: 0.46,
    ),
    MixerSoundItem(
      key: 'stream',
      title: 'Stream',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/rain.mp3',
      icon: Icons.water_drop_outlined,
      defaultVolume: 0.62,
    ),
    MixerSoundItem(
      key: 'waves',
      title: 'Ocean Waves',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/ocean.mp3',
      icon: Icons.waves_rounded,
      defaultVolume: 0.74,
    ),
    MixerSoundItem(
      key: 'wind',
      title: 'Wind',
      category: MixerCategory.nature,
      assetPath: 'audio/ambient/forest.mp3',
      icon: Icons.air_rounded,
      defaultVolume: 0.42,
    ),
    MixerSoundItem(
      key: 'birds',
      title: 'Birds',
      category: MixerCategory.animals,
      assetPath: 'audio/ambient/forest.mp3',
      icon: Icons.flutter_dash_rounded,
      badgeText: '24',
      defaultVolume: 0.36,
    ),
    MixerSoundItem(
      key: 'crickets',
      title: 'Crickets',
      category: MixerCategory.animals,
      assetPath: 'audio/ambient/night.mp3',
      icon: Icons.cruelty_free_rounded,
      defaultVolume: 0.42,
    ),
  ];
}

class MeditationTrack {
  final String key;
  final String title;
  final String subtitle;
  final String audioAsset;
  final String backgroundAsset;
  final IconData icon;
  final Color color;
  final Color secondColor;
  final AmbientBackgroundType backgroundType;
  final bool isPremium;
  final List<String> defaultMixerKeys;

  const MeditationTrack({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.audioAsset,
    required this.backgroundAsset,
    required this.icon,
    required this.color,
    required this.secondColor,
    required this.backgroundType,
    this.isPremium = false,
    this.defaultMixerKeys = const ['birds'],
  });
}

class MixerSoundItem {
  final String key;
  final String title;
  final MixerCategory category;
  final String assetPath;
  final IconData icon;
  final String? badgeText;
  final double defaultVolume;

  const MixerSoundItem({
    required this.key,
    required this.title,
    required this.category,
    required this.assetPath,
    required this.icon,
    this.badgeText,
    this.defaultVolume = 0.55,
  });
}

class ActiveMixerSound {
  final MixerSoundItem item;
  final double volume;

  const ActiveMixerSound({
    required this.item,
    required this.volume,
  });

  ActiveMixerSound copyWith({
    MixerSoundItem? item,
    double? volume,
  }) {
    return ActiveMixerSound(
      item: item ?? this.item,
      volume: volume ?? this.volume,
    );
  }
}

enum MixerCategory {
  music,
  nature,
  animals,
}

enum AmbientBackgroundType {
  glow,
  forestBeach,
  water,
  ocean,
  forest,
  night,
  mountain,
}

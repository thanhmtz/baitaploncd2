// File: lib/ui/screens/together/together_screen.dart
// Bản đã xóa mặt đất cũ vẽ bằng CustomPainter.
// Cây/ảnh mới đã tự có bãi đất trong EvolvingCactusPet.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_tracker/providers/tree_provider.dart';
import 'package:health_tracker/shared/services/tree_service.dart';
import 'package:health_tracker/ui/screens/together/meditation_screen.dart';
import 'package:health_tracker/ui/widgets/tree_3d_effects.dart';
import 'package:health_tracker/ui/widgets/tree_art_painters.dart';
import 'package:health_tracker/ui/widgets/real_time_sky_background.dart';
import 'package:health_tracker/ui/widgets/evolving_cactus_pet.dart';
import 'package:health_tracker/ui/widgets/cactus_visual_state.dart';
import 'package:provider/provider.dart';

class TogetherScreen extends StatefulWidget {
  const TogetherScreen({Key? key}) : super(key: key);

  @override
  State<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends State<TogetherScreen> {
  late final Future<TreeProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = TreeService().getProvider().then((provider) {
      TreeService.setSharedProvider(provider);
      return provider;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<TreeProvider>(
      future: _providerFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF1A3A2F),
                          Color(0xFF2D5A47),
                          Color(0xFF3D7A5F),
                        ]
                      : const [
                          Color(0xFF0A9AB7),
                          Color(0xFF5CE4D1),
                          Color(0xFFE1FF9E),
                        ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        return ChangeNotifierProvider<TreeProvider>.value(
          value: snapshot.data!,
          child: const Scaffold(
            body: _TogetherBody(),
          ),
        );
      },
    );
  }
}

class _TogetherBody extends StatelessWidget {
  const _TogetherBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<TreeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFF1A3A2F),
                        Color(0xFF2D5A47),
                        Color(0xFF3D7A5F),
                      ]
                    : const [
                        Color(0xFF0A9AB7),
                        Color(0xFF5CE4D1),
                        Color(0xFFE1FF9E),
                      ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return _TreeScreenContent(provider: provider);
      },
    );
  }
}

class _TreeScreenContent extends StatefulWidget {
  final TreeProvider provider;

  const _TreeScreenContent({
    super.key,
    required this.provider,
  });

  @override
  State<_TreeScreenContent> createState() => _TreeScreenContentState();
}

class _TreeScreenContentState extends State<_TreeScreenContent>
    with TickerProviderStateMixin {
  late final AnimationController _swayController;
  late final AnimationController _floatController;
  late final AnimationController _levelUpController;
  late final AnimationController _pulseController;
  late final AnimationController _tapController;
  late final AnimationController _sparkleController;

  late final Animation<double> _swayAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _levelUpAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _tapAnimation;
  late final Animation<double> _sparkleAnimation;

  bool _showLevelUp = false;
  bool _treeImagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_treeImagesPrecached) return;
    _treeImagesPrecached = true;

    for (final assetPath in meadowTreeAssetPaths) {
      precacheImage(AssetImage(assetPath), context);
    }
  }

  @override
  void initState() {
    super.initState();

    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.035, end: 0.035).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _levelUpAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _tapAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_tapController);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();

    _sparkleAnimation = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.linear,
    );

    _levelUpController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showLevelUp = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _swayController.dispose();
    _floatController.dispose();
    _levelUpController.dispose();
    _pulseController.dispose();
    _tapController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Giữ nguyên RealTimeSkyBackground.
        // File real_time_sky_background.dart đã được sửa để chỉ vẽ bầu trời.
        const Positioned.fill(
          child: RealTimeSkyBackground(),
        ),

        Positioned(
          top: topPadding + 14,
          left: 22,
          right: 22,
          child: Row(
            children: [
              Expanded(child: _TopStatusBar(provider: provider)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelpDialog(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Color(0xFF5CE4D1),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: topPadding + 98,
          left: 30,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              );
            },
            child: const _SmallRoundPlantButton(),
          ),
        ),

        Positioned(
          top: topPadding + 100,
          right: 76,
          child: _TopIconButton(
            icon: Icons.self_improvement_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeditationScreen()),
              );
            },
          ),
        ),

        Positioned(
          top: topPadding + 100,
          right: 24,
          child: _TopIconButton(
            icon: Icons.camera_alt_rounded,
            onTap: () {
              _showToast(context, 'Tính năng chụp ảnh đang phát triển');
            },
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 132,
          child: Center(
            child: GestureDetector(
              onTap: () => _petTree(provider),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _swayAnimation,
                  _floatAnimation,
                  _pulseAnimation,
                  _tapAnimation,
                  _sparkleAnimation,
                ]),
                builder: (context, child) {
                  return Tree3DStage(
                    sway: _swayAnimation.value,
                    floatY: _floatAnimation.value * 0.55,
                    pulse: _pulseAnimation.value,
                    tapScale: _tapAnimation.value,
                    sparkleProgress: _sparkleAnimation.value,
                    showSparkles: _showLevelUp,
                    width: 272,
                    height: 306,
                    child: child!,
                  );
                },
                child: EvolvingCactusPet(
                  level: provider.treeLevel,
                  visualState: provider.cactusVisualState,
                  width: 340,
                  height: 430,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right: 18,
          bottom: 122,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showLeaderboard(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFB800),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const LadybugArt(),
            ],
          ),
        ),

        if (_showLevelUp)
          Center(
            child: AnimatedBuilder(
              animation: _levelUpAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _levelUpAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Level Up!',
                      style: TextStyle(
                        color: Color(0xFFFF8A2A),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _petTree(TreeProvider provider) async {
    _tapController.forward(from: 0);

    final oldLevel = provider.treeLevel;

    await provider.addXpFromActivity(
      type: 'pet_tree',
      baseXp: 1,
      completed: false,
    );

    if (!mounted) return;

    if (provider.treeLevel > oldLevel) {
      _playLevelUp();
    }
  }

  void _playLevelUp() {
    setState(() {
      _showLevelUp = true;
    });

    _levelUpController.forward(from: 0);
  }

  void _showToast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LeaderboardSheet(provider: widget.provider),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A23) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: isDark
                      ? const Color(0xFF5CE4D1)
                      : const Color(0xFF5CE4D1),
                  size: 48,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Cách Tăng Level Cây',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF263238),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(Icons.water_drop_rounded, 'Uống nước', '+10 XP', isDark),
              _buildHelpItem(Icons.directions_walk_rounded, 'Đi bộ 10K bước', '+15 XP', isDark),
              _buildHelpItem(Icons.air_rounded, 'Thiền 5+ phút', '+10 XP', isDark),
              _buildHelpItem(Icons.local_fire_department_rounded, 'Ăn uống lành mạnh', '+20 XP', isDark),
              _buildHelpItem(Icons.favorite_rounded, 'Đo nhịp tim', '+10 XP', isDark),
              _buildHelpItem(Icons.monitor_weight_rounded, 'Cân nặng', '+5 XP', isDark),
              _buildHelpItem(Icons.nights_stay_rounded, 'Ngủ ngon', '+15 XP', isDark),
              const Divider(height: 24),
              _buildHelpItem(Icons.timer_rounded, 'Tự động', '+1 XP/phút', isDark),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.shade900.withOpacity(0.3)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak Bonus',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '3 ngày: x1.2',
                      style: TextStyle(
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                      ),
                    ),
                    Text(
                      '7 ngày: x1.3',
                      style: TextStyle(
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                      ),
                    ),
                    Text(
                      '14 ngày: x1.5 + Bloom 🌸',
                      style: TextStyle(
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Đã hiểu',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF5CE4D1)
                          : const Color(0xFF5CE4D1),
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

  Widget _buildHelpItem(IconData icon, String title, String xp, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5CE4D1), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF263238),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF31BDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              xp,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSheet extends StatefulWidget {
  final TreeProvider provider;

  const _LeaderboardSheet({required this.provider});

  @override
  State<_LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<_LeaderboardSheet> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> users = [];
      final currentUser = FirebaseAuth.instance.currentUser;

      for (final doc in snapshot.docs) {
        final uid = doc.id;

        final treeData = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tree_data')
            .doc('main')
            .get();

        if (treeData.exists) {
          final data = treeData.data()!;
          users.add({
            'uid': uid,
            'username': doc.data()['username'] ?? 'User',
            'photoUrl': doc.data()['photoUrl'],
            'totalXp': data['totalXp'] ?? 0,
            'treeLevel': data['treeLevel'] ?? 1,
            'isCurrentUser': uid == currentUser?.uid,
          });
        }
      }

      if (currentUser != null) {
        final existingIndex = users.indexWhere((u) => u['uid'] == currentUser.uid);
        if (existingIndex < 0) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          users.add({
            'uid': currentUser.uid,
            'username': userDoc.data()?['username'] ?? 'You',
            'photoUrl': userDoc.data()?['photoUrl'],
            'totalXp': widget.provider.totalXp,
            'treeLevel': widget.provider.treeLevel,
            'isCurrentUser': true,
          });
        }
      }

      users.sort((a, b) => (b['totalXp'] as int).compareTo(a['totalXp'] as int));

      if (!mounted) return;
      setState(() {
        _leaderboard = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading leaderboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final myRank = _leaderboard.indexWhere((u) => u['uid'] == currentUser?.uid) + 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A23) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB800), size: 28),
              const SizedBox(width: 8),
              Text(
                'Bảng Xếp Hạng',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF263238),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (myRank > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Hạng #$myRank',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leaderboard.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có dữ liệu',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          final rank = index + 1;
                          final isCurrentUser = user['isCurrentUser'] == true;

                          Color rankColor;
                          IconData? rankIcon;
                          if (rank == 1) {
                            rankColor = const Color(0xFFFFD700);
                            rankIcon = Icons.looks_one_rounded;
                          } else if (rank == 2) {
                            rankColor = const Color(0xFFC0C0C0);
                            rankIcon = Icons.looks_two_rounded;
                          } else if (rank == 3) {
                            rankColor = const Color(0xFFCD7F32);
                            rankIcon = Icons.looks_3_rounded;
                          } else {
                            rankColor = Colors.grey.shade400;
                            rankIcon = null;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? (isDark
                                      ? Colors.blue.shade900.withOpacity(0.3)
                                      : Colors.blue.shade50)
                                  : (isDark ? const Color(0xFF2A3A2E) : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(16),
                              border: isCurrentUser
                                  ? Border.all(color: Colors.blue.shade300, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: rankColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: rankIcon != null
                                        ? Icon(rankIcon, color: rankColor, size: 24)
                                        : Text(
                                            '#$rank',
                                            style: TextStyle(
                                              color: rankColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                    image: user['photoUrl'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(user['photoUrl'] as String),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: user['photoUrl'] == null
                                      ? Center(
                                          child: Text(
                                            (user['username'] as String).substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCurrentUser ? 'Bạn' : user['username'] as String,
                                        style: TextStyle(
                                          color: isCurrentUser
                                              ? Colors.blue.shade300
                                              : (isDark ? Colors.white : const Color(0xFF263238)),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'LV.${user['treeLevel']}',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${user['totalXp']}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF263238),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'XP',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final TreeProvider provider;

  const _TopStatusBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const MiniPlantAvatarArt(),
              Positioned(
                right: -2,
                bottom: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BA9F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cactus',
                      style: TextStyle(
                        color: Color(0xFF8A8E99),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lv${provider.treeLevel}',
                      style: const TextStyle(
                        color: Color(0xFF7DDF3D),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.currentStage.name,
                      style: const TextStyle(
                        color: Color(0xFFB0B3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                provider.treeLevel >= TreeProvider.maxLevel
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'MAX LEVEL',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(
                              color: Color(0xFF1AA5EF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF24BDF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${provider.todayXp} XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    minHeight: 14,
                                    value: provider.levelProgress,
                                    backgroundColor: const Color(0xFFE4E8EE),
                                    color: const Color(0xFF31BDF5),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment(
                                    (provider.levelProgress * 2 - 1).clamp(-0.85, 0.85),
                                    0,
                                  ),
                                  child: Container(
                                    width: 17,
                                    height: 17,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC9CDD5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(provider.levelProgress * 100).round()}%',
                            style: const TextStyle(
                              color: Color(0xFF1AA5EF),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _SmallRoundPlantButton extends StatelessWidget {
  const _SmallRoundPlantButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF66A),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFF7AB5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: MiniFlowerArt(),
      ),
    );
  }
}

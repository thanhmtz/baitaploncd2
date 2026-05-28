import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CoinShopScreen extends StatefulWidget {
  const CoinShopScreen({Key? key}) : super(key: key);

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  static const Color greenColor = Color(0xFF58B40B);
  static const Color coinColor = Color(0xFFFF9800);

  int _coins = 0;
  bool _isLoading = true;

  String _selectedAvatar = 'avocado';
  List<String> _unlockedAvatars = ['avocado'];

  final List<Map<String, dynamic>> _avatars = [
    {
      'id': 'avocado',
      'name': 'Avocado',
      'price': 0,
      'painter': const AvocadoMascotPainter(),
    },
    {
      'id': 'piggy',
      'name': 'Piggy',
      'price': 250,
      'painter': const PiggyMascotPainter(),
    },
    {
      'id': 'rabbit',
      'name': 'Rabbit',
      'price': 300,
      'painter': const RabbitMascotPainter(),
    },
    {
      'id': 'miu',
      'name': 'Miu',
      'price': 450,
      'painter': const MiuMascotPainter(),
    },
    {
      'id': 'bamboo',
      'name': 'Bamboo',
      'price': 450,
      'painter': const BambooMascotPainter(),
    },
    {
      'id': 'diamond_dragon',
      'name': 'Dragon',
      'price': 1,
      'painter': const DiamondDragonMascotPainter(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};

        _coins = (data['coins'] ?? 0).toInt();
        _selectedAvatar = data['selectedAvatar'] ?? 'avocado';

        if (data['unlockedAvatars'] is List) {
          _unlockedAvatars = List<String>.from(data['unlockedAvatars']);
        }

        if (!_unlockedAvatars.contains('avocado')) {
          _unlockedAvatars.add('avocado');
        }
      }
    } catch (e) {
      debugPrint('Error loading avatar shop: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAvatar(String avatarId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'selectedAvatar': avatarId,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _selectedAvatar = avatarId;
        });
      }
    } catch (e) {
      debugPrint('Error selecting avatar: $e');
    }
  }

  Future<void> _buyAvatar(Map<String, dynamic> avatar) async {
    final avatarId = avatar['id'] as String;
    final price = avatar['price'] as int;

    if (_coins < price) {
      _showCoinToast('Không đủ Coin!');
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'coins': FieldValue.increment(-price),
        'unlockedAvatars': FieldValue.arrayUnion([avatarId]),
        'selectedAvatar': avatarId,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _coins -= price;
          _selectedAvatar = avatarId;

          if (!_unlockedAvatars.contains(avatarId)) {
            _unlockedAvatars.add(avatarId);
          }
        });
          _showSuccessToast('Đã mua ${avatar["name"]}!');
      }
    } catch (e) {
      debugPrint('Error buying avatar: $e');
    }
  }

  void _handleAvatarTap(Map<String, dynamic> avatar) {
    final avatarId = avatar['id'] as String;
    final price = avatar['price'] as int;
    final isUnlocked = _unlockedAvatars.contains(avatarId);

    if (isUnlocked || price == 0) {
      _selectAvatar(avatarId);
    } else {
      _showBuyDialog(avatar);
    }
  }

  Widget _buildMascot(
    Map<String, dynamic> avatar, {
    double width = 150,
  }) {
    const double mascotRatio = 170 / 210;

    return SizedBox(
      width: width,
      height: width * mascotRatio,
      child: CustomPaint(
        painter: avatar['painter'] as CustomPainter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subTextColor = textColor.withOpacity(0.68);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(textColor),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 58, 16, 32),
                      itemCount: _avatars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final avatarId = avatar['id'] as String;
                        final price = avatar['price'] as int;

                        final isSelected = avatarId == _selectedAvatar;
                        final isUnlocked =
                            _unlockedAvatars.contains(avatarId) || price == 0;

                        return _buildAvatarCard(
                          avatar: avatar,
                          isSelected: isSelected,
                          isUnlocked: isUnlocked,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: textColor,
                size: 32,
              ),
            ),
          ),
          Text(
            'Giao diện',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _coinIcon(size: 33, fontSize: 17),
                  const SizedBox(width: 8),
                  Text(
                    '$_coins',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard({
    required Map<String, dynamic> avatar,
    required bool isSelected,
    required bool isUnlocked,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final price = avatar['price'] as int;
    final isFree = price == 0;

    return GestureDetector(
      onTap: () => _handleAvatarTap(avatar),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? greenColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _buildMascot(avatar, width: 150),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              avatar['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (isFree)
              const Text(
                'Miễn phí',
                style: TextStyle(
                  color: greenColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (isUnlocked)
              Text(
                isSelected ? 'Đang dùng' : 'Đã mở khóa',
                style: TextStyle(
                  color: isSelected ? greenColor : subTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _coinIcon(size: 26, fontSize: 13),
                  const SizedBox(width: 8),
                  Text(
                    '$price',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _coinIcon({
    required double size,
    required double fontSize,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: coinColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        '₿',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showBuyDialog(Map<String, dynamic> avatar) {
    final price = avatar['price'] as int;

    showDialog(
      context: context,
      builder: (context) {
        final textColor = Theme.of(context).colorScheme.onSurface;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Mua ${avatar["name"]}?',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMascot(avatar, width: 165),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _coinIcon(size: 30, fontSize: 15),
                  const SizedBox(width: 8),
                  Text(
                    '$price',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: greenColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _buyAvatar(avatar);
              },
              child: const Text(
                'Mua',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
 void _showCoinToast(String text) {
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        tween: Tween(begin: -120, end: 40),
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
                            color: const Color(0xFFE76B5B),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: Color(0xFFE76B5B),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
}
 void _showSuccessToast(String text) {
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        tween: Tween(begin: -120, end: 40),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF58B40B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
}
}

class _AvatarKit {
  static Paint stroke([double width = 4.2]) {
    return Paint()
      ..color = const Color(0xFF242424)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  static Paint fill(Color color) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  static Paint gradient(Rect rect, List<Color> colors) {
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
  }

  static void ground(Canvas canvas, Color color) {
    canvas.drawOval(
      const Rect.fromLTWH(42, 151, 126, 17),
      fill(color.withOpacity(0.28)),
    );
  }

  static void path(Canvas canvas, Path path, Paint paint, Paint stroke) {
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  static void oval(Canvas canvas, Rect rect, Paint paint, Paint stroke) {
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, stroke);
  }

  static void circle(Canvas canvas, Offset center, double radius, Paint paint, Paint stroke) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, stroke);
  }

  static void eye(Canvas canvas, Offset center, {double r = 7}) {
    final black = fill(const Color(0xFF202124));
    final white = fill(Colors.white);

    canvas.drawCircle(center, r, black);
    canvas.drawCircle(Offset(center.dx - r * 0.35, center.dy - r * 0.38), r * 0.28, white);
    canvas.drawCircle(Offset(center.dx + r * 0.25, center.dy + r * 0.22), r * 0.15, white);
  }

  static void smile(Canvas canvas, Offset start, Offset control, Offset end) {
    final p = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(p, stroke(3.4));
  }

  static void blush(Canvas canvas, Offset center, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 18, height: 10),
      fill(color.withOpacity(0.38)),
    );
  }

  static void sparkle(Canvas canvas, Offset center, double r, Color color) {
    final p = Path();
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final radius = i.isEven ? r : r * 0.42;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();

    canvas.drawPath(p, fill(color));
    canvas.drawPath(p, stroke(2.4));
  }

  static void feet(Canvas canvas, Color color) {
    oval(
      canvas,
      const Rect.fromLTWH(55, 148, 35, 16),
      fill(color),
      stroke(3.8),
    );
    oval(
      canvas,
      const Rect.fromLTWH(120, 148, 35, 16),
      fill(color),
      stroke(3.8),
    );
  }

  static void arms(Canvas canvas, Offset leftStart, Offset leftEnd, Offset rightStart, Offset rightEnd) {
    final s = stroke(4);
    canvas.drawLine(leftStart, leftEnd, s);
    canvas.drawLine(rightStart, rightEnd, s);
    canvas.drawCircle(leftEnd, 5.2, fill(const Color(0xFF242424)));
    canvas.drawCircle(rightEnd, 5.2, fill(const Color(0xFF242424)));
  }
}

class AvocadoMascotPainter extends CustomPainter {
  const AvocadoMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke();
    _AvatarKit.ground(canvas, const Color(0xFF79D35A));

    final body = Path()
      ..moveTo(103, 10)
      ..cubicTo(72, 18, 45, 54, 33, 91)
      ..cubicTo(18, 137, 52, 165, 103, 165)
      ..cubicTo(155, 165, 190, 136, 174, 91)
      ..cubicTo(161, 53, 133, 18, 103, 10)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(30, 10, 150, 155),
        [
          const Color(0xFFB9F07B),
          const Color(0xFF58B40B),
        ],
      ),
      s,
    );

    final inner = Path()
      ..moveTo(103, 38)
      ..cubicTo(78, 45, 58, 74, 52, 106)
      ..cubicTo(44, 143, 72, 157, 103, 157)
      ..cubicTo(136, 157, 165, 143, 156, 106)
      ..cubicTo(149, 74, 128, 45, 103, 38)
      ..close();

    _AvatarKit.path(
      canvas,
      inner,
      _AvatarKit.gradient(
        const Rect.fromLTWH(52, 38, 104, 119),
        [
          const Color(0xFFFFF4C7),
          const Color(0xFFFFD67A),
        ],
      ),
      s,
    );

    final leaf = Path()
      ..moveTo(108, 16)
      ..cubicTo(129, -2, 161, 6, 174, 30)
      ..cubicTo(146, 35, 124, 30, 108, 16)
      ..close();

    _AvatarKit.path(canvas, leaf, _AvatarKit.fill(const Color(0xFF74D14C)), s);
    canvas.drawLine(const Offset(125, 13), const Offset(170, 29), _AvatarKit.stroke(2.6));

    _AvatarKit.oval(
      canvas,
      const Rect.fromLTWH(78, 106, 50, 45),
      _AvatarKit.gradient(
        const Rect.fromLTWH(78, 106, 50, 45),
        [
          const Color(0xFF8B4F25),
          const Color(0xFF4B2A16),
        ],
      ),
      s,
    );

    _AvatarKit.eye(canvas, const Offset(78, 78), r: 7);
    _AvatarKit.eye(canvas, const Offset(128, 78), r: 7);
    _AvatarKit.smile(canvas, const Offset(91, 92), const Offset(103, 101), const Offset(115, 92));
    _AvatarKit.blush(canvas, const Offset(64, 94), const Color(0xFFFF8BA7));
    _AvatarKit.blush(canvas, const Offset(142, 94), const Color(0xFFFF8BA7));

    _AvatarKit.arms(
      canvas,
      const Offset(51, 112),
      const Offset(29, 127),
      const Offset(155, 112),
      const Offset(181, 95),
    );

    _AvatarKit.feet(canvas, const Color(0xFFFFF4C7));

    _AvatarKit.sparkle(canvas, const Offset(168, 55), 7, const Color(0xFFFFD54F));
    _AvatarKit.sparkle(canvas, const Offset(40, 48), 5, const Color(0xFFFFFFFF));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PiggyMascotPainter extends CustomPainter {
  const PiggyMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke();
    _AvatarKit.ground(canvas, const Color(0xFFFF8FA3));

    final leftEar = Path()
      ..moveTo(65, 43)
      ..cubicTo(48, 18, 26, 25, 33, 57)
      ..cubicTo(47, 58, 59, 51, 65, 43)
      ..close();

    final rightEar = Path()
      ..moveTo(145, 43)
      ..cubicTo(162, 18, 184, 25, 177, 57)
      ..cubicTo(163, 58, 151, 51, 145, 43)
      ..close();

    _AvatarKit.path(canvas, leftEar, _AvatarKit.fill(const Color(0xFFFFB7C8)), s);
    _AvatarKit.path(canvas, rightEar, _AvatarKit.fill(const Color(0xFFFFB7C8)), s);

    final body = Path()
      ..moveTo(105, 29)
      ..cubicTo(62, 29, 35, 60, 35, 102)
      ..cubicTo(35, 145, 66, 165, 105, 165)
      ..cubicTo(145, 165, 176, 145, 176, 102)
      ..cubicTo(176, 60, 148, 29, 105, 29)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(35, 29, 141, 136),
        [
          const Color(0xFFFFD5DF),
          const Color(0xFFFF8FA3),
        ],
      ),
      s,
    );

    _AvatarKit.eye(canvas, const Offset(77, 79), r: 7.5);
    _AvatarKit.eye(canvas, const Offset(133, 79), r: 7.5);

    _AvatarKit.oval(
      canvas,
      const Rect.fromLTWH(83, 88, 44, 28),
      _AvatarKit.fill(const Color(0xFFFFC5D1)),
      s,
    );

    canvas.drawCircle(const Offset(97, 101), 3.8, _AvatarKit.fill(const Color(0xFF242424)));
    canvas.drawCircle(const Offset(113, 101), 3.8, _AvatarKit.fill(const Color(0xFF242424)));

    _AvatarKit.smile(canvas, const Offset(91, 123), const Offset(105, 133), const Offset(119, 123));
    _AvatarKit.blush(canvas, const Offset(61, 100), const Color(0xFFFF5D83));
    _AvatarKit.blush(canvas, const Offset(149, 100), const Color(0xFFFF5D83));

    final apple = Path()
      ..moveTo(56, 114)
      ..cubicTo(45, 112, 38, 123, 43, 137)
      ..cubicTo(49, 154, 68, 153, 73, 138)
      ..cubicTo(78, 123, 68, 112, 56, 114)
      ..close();

    _AvatarKit.path(canvas, apple, _AvatarKit.fill(const Color(0xFFFF5252)), s);

    final leaf = Path()
      ..moveTo(61, 112)
      ..cubicTo(67, 97, 82, 101, 80, 113)
      ..cubicTo(72, 117, 66, 116, 61, 112)
      ..close();

    _AvatarKit.path(canvas, leaf, _AvatarKit.fill(const Color(0xFF58B40B)), s);

    final tail = Path()
      ..moveTo(176, 111)
      ..cubicTo(195, 102, 202, 124, 185, 125)
      ..cubicTo(173, 126, 178, 109, 190, 113);

    canvas.drawPath(tail, _AvatarKit.stroke(4));

    _AvatarKit.arms(
      canvas,
      const Offset(48, 120),
      const Offset(26, 132),
      const Offset(162, 120),
      const Offset(184, 133),
    );

    _AvatarKit.feet(canvas, const Color(0xFFFFC5D1));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RabbitMascotPainter extends CustomPainter {
  const RabbitMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke();
    _AvatarKit.ground(canvas, const Color(0xFFFFC46B));

    final leftEar = Path()
      ..moveTo(72, 62)
      ..cubicTo(47, 17, 25, 8, 25, 50)
      ..cubicTo(28, 78, 52, 88, 72, 62)
      ..close();

    final rightEar = Path()
      ..moveTo(138, 62)
      ..cubicTo(163, 17, 185, 8, 185, 50)
      ..cubicTo(182, 78, 158, 88, 138, 62)
      ..close();

    _AvatarKit.path(canvas, leftEar, _AvatarKit.fill(Colors.white), s);
    _AvatarKit.path(canvas, rightEar, _AvatarKit.fill(Colors.white), s);

    final innerLeft = Path()
      ..moveTo(62, 60)
      ..cubicTo(45, 31, 36, 28, 38, 52)
      ..cubicTo(40, 66, 51, 72, 62, 60)
      ..close();

    final innerRight = Path()
      ..moveTo(148, 60)
      ..cubicTo(165, 31, 174, 28, 172, 52)
      ..cubicTo(170, 66, 159, 72, 148, 60)
      ..close();

    canvas.drawPath(innerLeft, _AvatarKit.fill(const Color(0xFFFFB3C7)));
    canvas.drawPath(innerRight, _AvatarKit.fill(const Color(0xFFFFB3C7)));

    final body = Path()
      ..moveTo(105, 45)
      ..cubicTo(66, 45, 40, 76, 40, 116)
      ..cubicTo(40, 151, 67, 165, 105, 165)
      ..cubicTo(143, 165, 170, 151, 170, 116)
      ..cubicTo(170, 76, 144, 45, 105, 45)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(40, 45, 130, 120),
        [
          Colors.white,
          const Color(0xFFFFF2E8),
        ],
      ),
      s,
    );

    _AvatarKit.eye(canvas, const Offset(84, 89), r: 7);
    _AvatarKit.eye(canvas, const Offset(126, 89), r: 7);

    canvas.drawOval(
      const Rect.fromLTWH(99, 99, 12, 8),
      _AvatarKit.fill(const Color(0xFFFF8FA3)),
    );

    _AvatarKit.smile(canvas, const Offset(105, 106), const Offset(96, 116), const Offset(88, 107));
    _AvatarKit.smile(canvas, const Offset(105, 106), const Offset(114, 116), const Offset(122, 107));

    canvas.drawLine(const Offset(75, 105), const Offset(51, 99), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(75, 113), const Offset(50, 115), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(135, 105), const Offset(159, 99), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(135, 113), const Offset(160, 115), _AvatarKit.stroke(2.8));

    final carrot = Path()
      ..moveTo(64, 130)
      ..lineTo(127, 105)
      ..lineTo(106, 145)
      ..close();

    _AvatarKit.path(
      canvas,
      carrot,
      _AvatarKit.gradient(
        const Rect.fromLTWH(64, 105, 63, 40),
        [
          const Color(0xFFFFA726),
          const Color(0xFFFF7043),
        ],
      ),
      s,
    );

    final carrotLeaf1 = Path()
      ..moveTo(126, 106)
      ..cubicTo(131, 89, 148, 93, 145, 110);

    final carrotLeaf2 = Path()
      ..moveTo(126, 106)
      ..cubicTo(120, 88, 105, 92, 111, 110);

    canvas.drawPath(carrotLeaf1, _AvatarKit.stroke(4));
    canvas.drawPath(carrotLeaf2, _AvatarKit.stroke(4));

    _AvatarKit.feet(canvas, Colors.white);
    _AvatarKit.blush(canvas, const Offset(70, 104), const Color(0xFFFF8FA3));
    _AvatarKit.blush(canvas, const Offset(140, 104), const Color(0xFFFF8FA3));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiuMascotPainter extends CustomPainter {
  const MiuMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke();
    _AvatarKit.ground(canvas, const Color(0xFFFFB35C));

    final body = Path()
      ..moveTo(68, 59)
      ..lineTo(54, 24)
      ..lineTo(88, 43)
      ..cubicTo(99, 38, 111, 38, 122, 43)
      ..lineTo(156, 24)
      ..lineTo(142, 59)
      ..cubicTo(162, 78, 169, 106, 160, 134)
      ..cubicTo(150, 162, 126, 166, 105, 166)
      ..cubicTo(84, 166, 60, 162, 50, 134)
      ..cubicTo(41, 106, 48, 78, 68, 59)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(48, 24, 116, 142),
        [
          const Color(0xFFFFE0B2),
          const Color(0xFFFFB35C),
        ],
      ),
      s,
    );

    final chest = Path()
      ..moveTo(105, 109)
      ..cubicTo(82, 112, 72, 134, 80, 154)
      ..cubicTo(93, 165, 118, 165, 131, 154)
      ..cubicTo(138, 134, 128, 112, 105, 109)
      ..close();

    canvas.drawPath(chest, _AvatarKit.fill(const Color(0xFFFFF3E0)));

    _AvatarKit.eye(canvas, const Offset(82, 84), r: 7.5);
    _AvatarKit.eye(canvas, const Offset(128, 84), r: 7.5);

    canvas.drawOval(
      const Rect.fromLTWH(99, 97, 12, 8),
      _AvatarKit.fill(const Color(0xFF242424)),
    );

    _AvatarKit.smile(canvas, const Offset(105, 105), const Offset(97, 114), const Offset(90, 106));
    _AvatarKit.smile(canvas, const Offset(105, 105), const Offset(113, 114), const Offset(120, 106));

    canvas.drawLine(const Offset(73, 100), const Offset(47, 94), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(73, 109), const Offset(46, 112), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(137, 100), const Offset(163, 94), _AvatarKit.stroke(2.8));
    canvas.drawLine(const Offset(137, 109), const Offset(164, 112), _AvatarKit.stroke(2.8));

    final fish = Path()
      ..moveTo(80, 129)
      ..cubicTo(99, 105, 134, 108, 151, 128)
      ..cubicTo(135, 150, 99, 150, 80, 129)
      ..close();

    _AvatarKit.path(
      canvas,
      fish,
      _AvatarKit.gradient(
        const Rect.fromLTWH(80, 108, 71, 42),
        [
          const Color(0xFFFFCA28),
          const Color(0xFFFF7043),
        ],
      ),
      s,
    );

    final tail = Path()
      ..moveTo(81, 129)
      ..lineTo(61, 113)
      ..lineTo(61, 145)
      ..close();

    _AvatarKit.path(canvas, tail, _AvatarKit.fill(const Color(0xFFFF8A50)), s);
    canvas.drawCircle(const Offset(137, 124), 3, _AvatarKit.fill(const Color(0xFF242424)));

    final catTail = Path()
      ..moveTo(158, 137)
      ..cubicTo(187, 136, 187, 92, 166, 100);

    canvas.drawPath(catTail, _AvatarKit.stroke(5));

    _AvatarKit.feet(canvas, const Color(0xFFFFE0B2));
    _AvatarKit.blush(canvas, const Offset(65, 102), const Color(0xFFFF8FA3));
    _AvatarKit.blush(canvas, const Offset(145, 102), const Color(0xFFFF8FA3));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BambooMascotPainter extends CustomPainter {
  const BambooMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke();
    _AvatarKit.ground(canvas, const Color(0xFF7CB342));

    canvas.drawCircle(const Offset(62, 48), 23, _AvatarKit.fill(const Color(0xFF242424)));
    canvas.drawCircle(const Offset(148, 48), 23, _AvatarKit.fill(const Color(0xFF242424)));

    final body = Path()
      ..moveTo(105, 25)
      ..cubicTo(62, 25, 34, 58, 34, 103)
      ..cubicTo(34, 146, 63, 165, 105, 165)
      ..cubicTo(147, 165, 176, 146, 176, 103)
      ..cubicTo(176, 58, 148, 25, 105, 25)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(34, 25, 142, 140),
        [
          Colors.white,
          const Color(0xFFEFEFEF),
        ],
      ),
      s,
    );

    _AvatarKit.oval(
      canvas,
      const Rect.fromLTWH(62, 73, 36, 44),
      _AvatarKit.fill(const Color(0xFF242424)),
      _AvatarKit.stroke(0),
    );

    _AvatarKit.oval(
      canvas,
      const Rect.fromLTWH(112, 73, 36, 44),
      _AvatarKit.fill(const Color(0xFF242424)),
      _AvatarKit.stroke(0),
    );

    canvas.drawCircle(const Offset(81, 91), 7.5, _AvatarKit.fill(Colors.white));
    canvas.drawCircle(const Offset(129, 91), 7.5, _AvatarKit.fill(Colors.white));
    canvas.drawCircle(const Offset(82, 92), 3.2, _AvatarKit.fill(const Color(0xFF242424)));
    canvas.drawCircle(const Offset(128, 92), 3.2, _AvatarKit.fill(const Color(0xFF242424)));

    canvas.drawOval(
      const Rect.fromLTWH(97, 105, 17, 11),
      _AvatarKit.fill(const Color(0xFF242424)),
    );

    _AvatarKit.smile(canvas, const Offset(105, 118), const Offset(97, 126), const Offset(89, 119));
    _AvatarKit.smile(canvas, const Offset(105, 118), const Offset(113, 126), const Offset(121, 119));

    canvas.drawOval(
      const Rect.fromLTWH(42, 118, 31, 31),
      _AvatarKit.fill(const Color(0xFF242424)),
    );

    canvas.drawOval(
      const Rect.fromLTWH(137, 118, 31, 31),
      _AvatarKit.fill(const Color(0xFF242424)),
    );

    canvas.save();
    canvas.translate(105, 130);
    canvas.rotate(-0.55);
    canvas.translate(-105, -130);

    final bamboo = RRect.fromRectAndRadius(
      const Rect.fromLTWH(91, 97, 29, 64),
      const Radius.circular(9),
    );

    canvas.drawRRect(
      bamboo,
      _AvatarKit.gradient(
        const Rect.fromLTWH(91, 97, 29, 64),
        [
          const Color(0xFFA5D66A),
          const Color(0xFF58B40B),
        ],
      ),
    );
    canvas.drawRRect(bamboo, s);

    canvas.drawLine(const Offset(91, 115), const Offset(120, 115), _AvatarKit.stroke(3));
    canvas.drawLine(const Offset(91, 136), const Offset(120, 136), _AvatarKit.stroke(3));

    final leaf1 = Path()
      ..moveTo(119, 108)
      ..cubicTo(143, 88, 158, 106, 133, 121)
      ..close();

    final leaf2 = Path()
      ..moveTo(91, 132)
      ..cubicTo(65, 121, 58, 142, 86, 146)
      ..close();

    _AvatarKit.path(canvas, leaf1, _AvatarKit.fill(const Color(0xFF7CB342)), s);
    _AvatarKit.path(canvas, leaf2, _AvatarKit.fill(const Color(0xFF7CB342)), s);

    canvas.restore();

    canvas.drawOval(const Rect.fromLTWH(55, 150, 34, 15), _AvatarKit.fill(const Color(0xFF242424)));
    canvas.drawOval(const Rect.fromLTWH(121, 150, 34, 15), _AvatarKit.fill(const Color(0xFF242424)));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiamondDragonMascotPainter extends CustomPainter {
  const DiamondDragonMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final s = _AvatarKit.stroke(4.4);
    _AvatarKit.ground(canvas, const Color(0xFF7C4DFF));

    canvas.drawCircle(
      const Offset(105, 88),
      76,
      _AvatarKit.fill(const Color(0xFFFFD54F).withOpacity(0.24)),
    );

    canvas.drawCircle(
      const Offset(105, 88),
      58,
      _AvatarKit.fill(const Color(0xFF80DEEA).withOpacity(0.18)),
    );

    _AvatarKit.sparkle(canvas, const Offset(27, 34), 8, const Color(0xFFFFD54F));
    _AvatarKit.sparkle(canvas, const Offset(184, 38), 7, const Color(0xFF80DEEA));
    _AvatarKit.sparkle(canvas, const Offset(34, 128), 6, Colors.white);
    _AvatarKit.sparkle(canvas, const Offset(181, 126), 6, const Color(0xFFFF8FA3));

    final leftWing = Path()
      ..moveTo(70, 83)
      ..cubicTo(38, 51, 16, 55, 11, 88)
      ..cubicTo(31, 78, 44, 91, 50, 110)
      ..cubicTo(55, 94, 63, 87, 70, 83)
      ..close();

    final rightWing = Path()
      ..moveTo(140, 83)
      ..cubicTo(172, 51, 194, 55, 199, 88)
      ..cubicTo(179, 78, 166, 91, 160, 110)
      ..cubicTo(155, 94, 147, 87, 140, 83)
      ..close();

    _AvatarKit.path(
      canvas,
      leftWing,
      _AvatarKit.gradient(
        const Rect.fromLTWH(11, 51, 59, 59),
        [
          const Color(0xFFB388FF),
          const Color(0xFF7C4DFF),
        ],
      ),
      s,
    );

    _AvatarKit.path(
      canvas,
      rightWing,
      _AvatarKit.gradient(
        const Rect.fromLTWH(140, 51, 59, 59),
        [
          const Color(0xFFB388FF),
          const Color(0xFF7C4DFF),
        ],
      ),
      s,
    );

    final tail = Path()
      ..moveTo(150, 129)
      ..cubicTo(183, 130, 187, 99, 166, 101)
      ..cubicTo(181, 90, 198, 101, 198, 120)
      ..cubicTo(198, 145, 168, 155, 145, 143);

    _AvatarKit.path(canvas, tail, _AvatarKit.fill(const Color(0xFFFFF8E1)), s);

    final body = Path()
      ..moveTo(105, 31)
      ..cubicTo(69, 31, 43, 62, 43, 105)
      ..cubicTo(43, 146, 69, 165, 105, 165)
      ..cubicTo(141, 165, 167, 146, 167, 105)
      ..cubicTo(167, 62, 141, 31, 105, 31)
      ..close();

    _AvatarKit.path(
      canvas,
      body,
      _AvatarKit.gradient(
        const Rect.fromLTWH(43, 31, 124, 134),
        [
          const Color(0xFFFFF8E1),
          const Color(0xFFFFE082),
        ],
      ),
      s,
    );

    final bellyGem = Path()
      ..moveTo(105, 92)
      ..lineTo(132, 118)
      ..lineTo(120, 153)
      ..lineTo(90, 153)
      ..lineTo(78, 118)
      ..close();

    _AvatarKit.path(
      canvas,
      bellyGem,
      _AvatarKit.gradient(
        const Rect.fromLTWH(78, 92, 54, 61),
        [
          const Color(0xFFB2EBF2),
          const Color(0xFF26C6DA),
        ],
      ),
      s,
    );

    canvas.drawLine(const Offset(105, 92), const Offset(105, 153), _AvatarKit.stroke(2.4));
    canvas.drawLine(const Offset(78, 118), const Offset(132, 118), _AvatarKit.stroke(2.4));

    final leftHorn = Path()
      ..moveTo(74, 45)
      ..lineTo(58, 18)
      ..lineTo(87, 36)
      ..close();

    final rightHorn = Path()
      ..moveTo(136, 45)
      ..lineTo(152, 18)
      ..lineTo(123, 36)
      ..close();

    _AvatarKit.path(canvas, leftHorn, _AvatarKit.fill(const Color(0xFFFFC107)), s);
    _AvatarKit.path(canvas, rightHorn, _AvatarKit.fill(const Color(0xFFFFC107)), s);

    final crown = Path()
      ..moveTo(77, 33)
      ..lineTo(86, 10)
      ..lineTo(99, 30)
      ..lineTo(105, 5)
      ..lineTo(112, 30)
      ..lineTo(125, 10)
      ..lineTo(134, 33)
      ..lineTo(128, 47)
      ..lineTo(83, 47)
      ..close();

    _AvatarKit.path(
      canvas,
      crown,
      _AvatarKit.gradient(
        const Rect.fromLTWH(77, 5, 57, 42),
        [
          const Color(0xFFFFF176),
          const Color(0xFFFFB300),
        ],
      ),
      s,
    );

    _AvatarKit.eye(canvas, const Offset(77, 79), r: 8.5);
    _AvatarKit.eye(canvas, const Offset(133, 79), r: 8.5);

    final snout = Path()
      ..moveTo(90, 94)
      ..cubicTo(97, 86, 113, 86, 120, 94)
      ..cubicTo(124, 105, 116, 116, 105, 116)
      ..cubicTo(94, 116, 86, 105, 90, 94)
      ..close();

    _AvatarKit.path(canvas, snout, _AvatarKit.fill(const Color(0xFFFFFDF4)), s);
    canvas.drawOval(
      const Rect.fromLTWH(100, 98, 10, 7),
      _AvatarKit.fill(const Color(0xFF242424)),
    );

    _AvatarKit.smile(canvas, const Offset(105, 105), const Offset(97, 113), const Offset(91, 106));
    _AvatarKit.smile(canvas, const Offset(105, 105), const Offset(113, 113), const Offset(119, 106));

    _AvatarKit.blush(canvas, const Offset(61, 100), const Color(0xFFFF8FA3));
    _AvatarKit.blush(canvas, const Offset(149, 100), const Color(0xFFFF8FA3));

    _AvatarKit.arms(
      canvas,
      const Offset(55, 114),
      const Offset(30, 103),
      const Offset(155, 114),
      const Offset(180, 103),
    );

    final handDiamond = Path()
      ..moveTo(29, 83)
      ..lineTo(43, 98)
      ..lineTo(29, 115)
      ..lineTo(15, 98)
      ..close();

    _AvatarKit.path(
      canvas,
      handDiamond,
      _AvatarKit.gradient(
        const Rect.fromLTWH(15, 83, 28, 32),
        [
          const Color(0xFFE0F7FA),
          const Color(0xFF26C6DA),
        ],
      ),
      s,
    );

    canvas.drawCircle(const Offset(181, 84), 14, _AvatarKit.fill(const Color(0xFFFF9800)));
    canvas.drawCircle(const Offset(181, 84), 14, s);
    canvas.drawCircle(const Offset(181, 84), 7, _AvatarKit.fill(const Color(0xFFFFD54F)));
    canvas.drawCircle(const Offset(181, 84), 7, s);

    _AvatarKit.feet(canvas, const Color(0xFFFFC107));

    _AvatarKit.sparkle(canvas, const Offset(105, 125), 8, Colors.white);
    _AvatarKit.sparkle(canvas, const Offset(122, 136), 5, const Color(0xFFFFD54F));
    _AvatarKit.sparkle(canvas, const Offset(89, 136), 5, const Color(0xFFFF8FA3));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
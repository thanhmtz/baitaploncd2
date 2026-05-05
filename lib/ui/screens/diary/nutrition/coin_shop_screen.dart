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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đổi avatar!'),
            backgroundColor: greenColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error selecting avatar: $e');
    }
  }

  Future<void> _buyAvatar(Map<String, dynamic> avatar) async {
    final avatarId = avatar['id'] as String;
    final price = avatar['price'] as int;

    if (_coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không đủ coin!'),
          backgroundColor: Colors.red,
        ),
      );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã mua ${avatar["name"]}!'),
            backgroundColor: greenColor,
          ),
        );
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
    double width = 145,
  }) {
    return SizedBox(
      width: width,
      height: width * 0.82,
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
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: _buildMascot(avatar, width: 145),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 14),
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
            const SizedBox(height: 24),
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
}

class AvocadoMascotPainter extends CustomPainter {
  const AvocadoMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 210;
    final sy = size.height / 170;

    canvas.save();
    canvas.scale(sx, sy);

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cheek = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    canvas.drawOval(const Rect.fromLTWH(48, 150, 30, 15), white);
    canvas.drawOval(const Rect.fromLTWH(124, 150, 30, 15), white);
    canvas.drawOval(const Rect.fromLTWH(48, 150, 30, 15), stroke);
    canvas.drawOval(const Rect.fromLTWH(124, 150, 30, 15), stroke);

    final body = Path()
      ..moveTo(96, 8)
      ..cubicTo(72, 15, 52, 42, 38, 72)
      ..cubicTo(17, 116, 36, 158, 91, 164)
      ..cubicTo(146, 170, 180, 138, 165, 91)
      ..cubicTo(153, 52, 127, 13, 96, 8)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    final leaf = Path()
      ..moveTo(104, 11)
      ..cubicTo(127, -8, 160, 4, 177, 29)
      ..cubicTo(149, 32, 126, 25, 104, 11)
      ..close();

    canvas.drawPath(leaf, white);
    canvas.drawPath(leaf, stroke);

    canvas.drawLine(const Offset(124, 8), const Offset(174, 28), stroke);

    canvas.drawOval(const Rect.fromLTWH(53, 92, 74, 71), black);

    canvas.drawOval(const Rect.fromLTWH(63, 103, 14, 9), white);

    canvas.drawCircle(const Offset(67, 68), 6.5, black);
    canvas.drawCircle(const Offset(116, 68), 6.5, black);

    canvas.drawCircle(const Offset(64, 66), 2.3, white);
    canvas.drawCircle(const Offset(113, 66), 2.3, white);

    final mouth = Path()
      ..moveTo(87, 80)
      ..quadraticBezierTo(94, 87, 101, 80);

    canvas.drawPath(mouth, stroke);

    canvas.drawCircle(const Offset(53, 82), 4.5, cheek);
    canvas.drawCircle(const Offset(128, 82), 4.5, cheek);

    canvas.drawLine(const Offset(44, 103), const Offset(30, 116), stroke);
    canvas.drawCircle(const Offset(27, 119), 4, black);

    canvas.drawLine(const Offset(152, 96), const Offset(178, 76), stroke);
    canvas.drawLine(const Offset(178, 76), const Offset(178, 45), stroke);
    canvas.drawLine(const Offset(178, 57), const Offset(167, 45), stroke);
    canvas.drawLine(const Offset(178, 57), const Offset(189, 45), stroke);

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

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final red = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = const Color(0xFF58B40B)
      ..style = PaintingStyle.fill;

    canvas.drawOval(const Rect.fromLTWH(52, 150, 30, 14), white);
    canvas.drawOval(const Rect.fromLTWH(125, 150, 30, 14), white);
    canvas.drawOval(const Rect.fromLTWH(52, 150, 30, 14), stroke);
    canvas.drawOval(const Rect.fromLTWH(125, 150, 30, 14), stroke);

    final leftEar = Path()
      ..moveTo(62, 35)
      ..cubicTo(43, 18, 28, 28, 33, 52)
      ..cubicTo(44, 50, 55, 44, 62, 35)
      ..close();

    final rightEar = Path()
      ..moveTo(148, 35)
      ..cubicTo(167, 18, 182, 28, 177, 52)
      ..cubicTo(166, 50, 155, 44, 148, 35)
      ..close();

    canvas.drawPath(leftEar, white);
    canvas.drawPath(leftEar, stroke);
    canvas.drawPath(rightEar, white);
    canvas.drawPath(rightEar, stroke);

    final body = Path()
      ..moveTo(105, 27)
      ..cubicTo(61, 27, 33, 60, 33, 101)
      ..cubicTo(33, 143, 65, 163, 107, 163)
      ..cubicTo(149, 163, 179, 142, 178, 101)
      ..cubicTo(177, 59, 149, 27, 105, 27)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    canvas.drawCircle(const Offset(76, 79), 8, black);
    canvas.drawCircle(const Offset(132, 79), 8, black);
    canvas.drawCircle(const Offset(73, 76), 2.5, white);
    canvas.drawCircle(const Offset(129, 76), 2.5, white);

    canvas.drawOval(const Rect.fromLTWH(84, 86, 42, 29), white);
    canvas.drawOval(const Rect.fromLTWH(84, 86, 42, 29), stroke);

    canvas.drawCircle(const Offset(97, 101), 3.8, black);
    canvas.drawCircle(const Offset(113, 101), 3.8, black);

    final smile = Path()
      ..moveTo(92, 120)
      ..quadraticBezierTo(105, 129, 119, 120);

    canvas.drawPath(smile, stroke);

    canvas.drawLine(const Offset(40, 118), const Offset(20, 130), stroke);
    canvas.drawLine(const Offset(170, 120), const Offset(191, 133), stroke);

    canvas.drawCircle(const Offset(62, 118), 16, red);
    canvas.drawCircle(const Offset(62, 118), 16, stroke);

    final leaf = Path()
      ..moveTo(62, 100)
      ..cubicTo(68, 88, 82, 92, 81, 104)
      ..cubicTo(72, 106, 66, 105, 62, 100)
      ..close();

    canvas.drawPath(leaf, green);
    canvas.drawPath(leaf, stroke);

    final tail = Path()
      ..moveTo(180, 105)
      ..cubicTo(199, 100, 199, 123, 184, 119)
      ..cubicTo(173, 116, 180, 105, 190, 109);

    canvas.drawPath(tail, stroke);

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

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final orange = Paint()
      ..color = const Color(0xFFFF7A1A)
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = const Color(0xFF58B40B)
      ..style = PaintingStyle.fill;

    final leftEar = Path()
      ..moveTo(68, 58)
      ..cubicTo(45, 15, 27, 5, 23, 47)
      ..cubicTo(27, 74, 49, 83, 68, 58)
      ..close();

    final rightEar = Path()
      ..moveTo(117, 56)
      ..cubicTo(137, 10, 159, 4, 162, 46)
      ..cubicTo(159, 74, 137, 83, 117, 56)
      ..close();

    canvas.drawPath(leftEar, white);
    canvas.drawPath(leftEar, stroke);
    canvas.drawPath(rightEar, white);
    canvas.drawPath(rightEar, stroke);

    final body = Path()
      ..moveTo(94, 45)
      ..cubicTo(55, 45, 33, 78, 34, 115)
      ..cubicTo(35, 150, 60, 165, 94, 165)
      ..cubicTo(130, 165, 157, 150, 158, 115)
      ..cubicTo(159, 78, 134, 45, 94, 45)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    canvas.drawOval(const Rect.fromLTWH(51, 151, 28, 13), white);
    canvas.drawOval(const Rect.fromLTWH(113, 151, 28, 13), white);
    canvas.drawOval(const Rect.fromLTWH(51, 151, 28, 13), stroke);
    canvas.drawOval(const Rect.fromLTWH(113, 151, 28, 13), stroke);

    canvas.drawCircle(const Offset(73, 88), 7, black);
    canvas.drawCircle(const Offset(113, 88), 7, black);
    canvas.drawCircle(const Offset(70, 85), 2.3, white);
    canvas.drawCircle(const Offset(110, 85), 2.3, white);

    canvas.drawOval(const Rect.fromLTWH(87, 96, 12, 8), white);
    canvas.drawOval(const Rect.fromLTWH(87, 96, 12, 8), stroke);

    final mouth = Path()
      ..moveTo(93, 104)
      ..quadraticBezierTo(86, 112, 79, 104)
      ..moveTo(93, 104)
      ..quadraticBezierTo(101, 112, 108, 104);

    canvas.drawPath(mouth, stroke);

    canvas.drawLine(const Offset(69, 103), const Offset(51, 98), stroke);
    canvas.drawLine(const Offset(69, 110), const Offset(50, 113), stroke);
    canvas.drawLine(const Offset(117, 103), const Offset(135, 98), stroke);
    canvas.drawLine(const Offset(117, 110), const Offset(136, 113), stroke);

    final carrot = Path()
      ..moveTo(58, 126)
      ..lineTo(112, 106)
      ..lineTo(98, 139)
      ..close();

    canvas.drawPath(carrot, orange);
    canvas.drawPath(carrot, stroke);

    canvas.drawLine(const Offset(74, 120), const Offset(85, 130), stroke);
    canvas.drawLine(const Offset(91, 113), const Offset(102, 123), stroke);

    final carrotLeaf1 = Path()
      ..moveTo(112, 106)
      ..cubicTo(120, 92, 132, 96, 132, 108);

    final carrotLeaf2 = Path()
      ..moveTo(112, 106)
      ..cubicTo(113, 90, 101, 86, 99, 103);

    canvas.drawPath(carrotLeaf1, green);
    canvas.drawPath(carrotLeaf1, stroke);
    canvas.drawPath(carrotLeaf2, green);
    canvas.drawPath(carrotLeaf2, stroke);

    canvas.drawLine(const Offset(45, 121), const Offset(60, 128), stroke);
    canvas.drawLine(const Offset(142, 122), const Offset(126, 129), stroke);

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

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final orange = Paint()
      ..color = const Color(0xFFFF7A1A)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(69, 58)
      ..lineTo(54, 23)
      ..lineTo(88, 42)
      ..cubicTo(101, 37, 115, 37, 128, 42)
      ..lineTo(160, 23)
      ..lineTo(147, 59)
      ..cubicTo(166, 78, 171, 106, 162, 133)
      ..cubicTo(151, 162, 126, 166, 105, 166)
      ..cubicTo(82, 166, 58, 161, 48, 133)
      ..cubicTo(39, 105, 47, 77, 69, 58)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    canvas.drawOval(const Rect.fromLTWH(63, 151, 27, 13), white);
    canvas.drawOval(const Rect.fromLTWH(121, 151, 27, 13), white);
    canvas.drawOval(const Rect.fromLTWH(63, 151, 27, 13), stroke);
    canvas.drawOval(const Rect.fromLTWH(121, 151, 27, 13), stroke);

    canvas.drawCircle(const Offset(82, 83), 7.5, black);
    canvas.drawCircle(const Offset(128, 83), 7.5, black);
    canvas.drawCircle(const Offset(79, 80), 2.5, white);
    canvas.drawCircle(const Offset(125, 80), 2.5, white);

    canvas.drawOval(const Rect.fromLTWH(99, 96, 12, 8), black);

    final mouth = Path()
      ..moveTo(105, 104)
      ..quadraticBezierTo(98, 112, 91, 105)
      ..moveTo(105, 104)
      ..quadraticBezierTo(112, 112, 119, 105);

    canvas.drawPath(mouth, stroke);

    canvas.drawLine(const Offset(74, 99), const Offset(49, 93), stroke);
    canvas.drawLine(const Offset(74, 108), const Offset(48, 110), stroke);
    canvas.drawLine(const Offset(136, 99), const Offset(161, 93), stroke);
    canvas.drawLine(const Offset(136, 108), const Offset(162, 110), stroke);

    final fish = Path()
      ..moveTo(85, 126)
      ..cubicTo(101, 105, 135, 108, 149, 126)
      ..cubicTo(134, 145, 101, 147, 85, 126)
      ..close();

    canvas.drawPath(fish, orange);
    canvas.drawPath(fish, stroke);

    final tail = Path()
      ..moveTo(85, 126)
      ..lineTo(66, 112)
      ..lineTo(66, 140)
      ..close();

    canvas.drawPath(tail, orange);
    canvas.drawPath(tail, stroke);

    canvas.drawCircle(const Offset(137, 123), 3, black);
    canvas.drawLine(const Offset(106, 112), const Offset(117, 126), stroke);
    canvas.drawLine(const Offset(106, 140), const Offset(117, 126), stroke);

    final catTail = Path()
      ..moveTo(160, 136)
      ..cubicTo(187, 133, 184, 91, 166, 100);

    canvas.drawPath(catTail, stroke);

    canvas.drawLine(const Offset(55, 120), const Offset(75, 130), stroke);
    canvas.drawLine(const Offset(154, 120), const Offset(136, 130), stroke);

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

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final green = Paint()
      ..color = const Color(0xFF8BC34A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(63, 48), 22, black);
    canvas.drawCircle(const Offset(145, 48), 22, black);

    final body = Path()
      ..moveTo(104, 25)
      ..cubicTo(61, 25, 33, 58, 33, 103)
      ..cubicTo(33, 145, 62, 164, 104, 164)
      ..cubicTo(146, 164, 176, 145, 176, 103)
      ..cubicTo(176, 58, 147, 25, 104, 25)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    canvas.drawOval(const Rect.fromLTWH(53, 150, 35, 15), black);
    canvas.drawOval(const Rect.fromLTWH(121, 150, 35, 15), black);

    canvas.drawOval(const Rect.fromLTWH(62, 75, 35, 43), black);
    canvas.drawOval(const Rect.fromLTWH(111, 75, 35, 43), black);

    canvas.drawCircle(const Offset(81, 91), 7, white);
    canvas.drawCircle(const Offset(128, 91), 7, white);
    canvas.drawCircle(const Offset(82, 92), 3, black);
    canvas.drawCircle(const Offset(127, 92), 3, black);

    canvas.drawOval(const Rect.fromLTWH(96, 104, 17, 11), black);

    final mouth = Path()
      ..moveTo(104, 116)
      ..quadraticBezierTo(96, 124, 88, 117)
      ..moveTo(104, 116)
      ..quadraticBezierTo(112, 124, 120, 117);

    canvas.drawPath(mouth, stroke);

    canvas.drawOval(const Rect.fromLTWH(42, 118, 30, 30), black);
    canvas.drawOval(const Rect.fromLTWH(138, 118, 30, 30), black);

    canvas.save();
    canvas.translate(105, 130);
    canvas.rotate(-0.55);
    canvas.translate(-105, -130);

    final bamboo = RRect.fromRectAndRadius(
      const Rect.fromLTWH(91, 100, 28, 61),
      const Radius.circular(8),
    );

    canvas.drawRRect(bamboo, green);
    canvas.drawRRect(bamboo, stroke);

    canvas.drawLine(const Offset(91, 116), const Offset(119, 116), stroke);
    canvas.drawLine(const Offset(91, 136), const Offset(119, 136), stroke);

    final leaf1 = Path()
      ..moveTo(118, 108)
      ..cubicTo(140, 92, 154, 107, 132, 119)
      ..close();

    final leaf2 = Path()
      ..moveTo(91, 130)
      ..cubicTo(67, 122, 60, 140, 86, 143)
      ..close();

    canvas.drawPath(leaf1, green);
    canvas.drawPath(leaf1, stroke);
    canvas.drawPath(leaf2, green);
    canvas.drawPath(leaf2, stroke);

    canvas.restore();

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

    final stroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final gold = Paint()
      ..color = const Color(0xFFFFC947)
      ..style = PaintingStyle.fill;

    final orangeGold = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;

    final diamond = Paint()
      ..color = const Color(0xFF76E4FF)
      ..style = PaintingStyle.fill;

    final blue = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.fill;

    final purple = Paint()
      ..color = const Color(0xFF9C27B0)
      ..style = PaintingStyle.fill;

    final softPink = Paint()
      ..color = const Color(0xFFFF8FB3)
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = const Color(0xFFFFC947).withOpacity(0.22)
      ..style = PaintingStyle.fill;

    // Glow background
    canvas.drawCircle(const Offset(105, 86), 76, glow);
    canvas.drawCircle(
      const Offset(105, 86),
      58,
      Paint()
        ..color = const Color(0xFF76E4FF).withOpacity(0.13)
        ..style = PaintingStyle.fill,
    );

    // Stars
    _drawStar(canvas, const Offset(26, 31), 8, gold, stroke);
    _drawStar(canvas, const Offset(183, 38), 7, gold, stroke);
    _drawStar(canvas, const Offset(181, 126), 6, diamond, stroke);
    _drawStar(canvas, const Offset(33, 128), 6, diamond, stroke);

    // Wings
    final leftWing = Path()
      ..moveTo(69, 79)
      ..cubicTo(39, 50, 18, 50, 11, 82)
      ..cubicTo(30, 73, 42, 85, 48, 104)
      ..cubicTo(54, 88, 63, 83, 69, 79)
      ..close();

    final rightWing = Path()
      ..moveTo(141, 79)
      ..cubicTo(171, 50, 192, 50, 199, 82)
      ..cubicTo(180, 73, 168, 85, 162, 104)
      ..cubicTo(156, 88, 147, 83, 141, 79)
      ..close();

    canvas.drawPath(leftWing, purple);
    canvas.drawPath(leftWing, stroke);
    canvas.drawPath(rightWing, purple);
    canvas.drawPath(rightWing, stroke);

    canvas.drawLine(const Offset(27, 78), const Offset(48, 104), stroke);
    canvas.drawLine(const Offset(183, 78), const Offset(162, 104), stroke);

    // Feet
    canvas.drawOval(const Rect.fromLTWH(54, 151, 31, 15), gold);
    canvas.drawOval(const Rect.fromLTWH(125, 151, 31, 15), gold);
    canvas.drawOval(const Rect.fromLTWH(54, 151, 31, 15), stroke);
    canvas.drawOval(const Rect.fromLTWH(125, 151, 31, 15), stroke);

    // Tail
    final tail = Path()
      ..moveTo(151, 128)
      ..cubicTo(182, 130, 185, 99, 164, 102)
      ..cubicTo(177, 92, 195, 101, 195, 119)
      ..cubicTo(194, 145, 166, 153, 145, 143);

    canvas.drawPath(tail, white);
    canvas.drawPath(tail, stroke);

    final tailGem = Path()
      ..moveTo(190, 118)
      ..lineTo(200, 107)
      ..lineTo(207, 120)
      ..lineTo(198, 132)
      ..close();

    canvas.drawPath(tailGem, diamond);
    canvas.drawPath(tailGem, stroke);

    // Body
    final body = Path()
      ..moveTo(105, 31)
      ..cubicTo(70, 31, 43, 62, 43, 105)
      ..cubicTo(43, 146, 69, 164, 105, 164)
      ..cubicTo(141, 164, 167, 146, 167, 105)
      ..cubicTo(167, 62, 140, 31, 105, 31)
      ..close();

    canvas.drawPath(body, white);
    canvas.drawPath(body, stroke);

    // Belly gem
    final belly = Path()
      ..moveTo(105, 95)
      ..lineTo(130, 118)
      ..lineTo(119, 151)
      ..lineTo(91, 151)
      ..lineTo(80, 118)
      ..close();

    canvas.drawPath(belly, diamond);
    canvas.drawPath(belly, stroke);

    canvas.drawLine(const Offset(105, 95), const Offset(105, 151), stroke);
    canvas.drawLine(const Offset(80, 118), const Offset(130, 118), stroke);

    // Head horns
    final leftHorn = Path()
      ..moveTo(72, 45)
      ..lineTo(57, 18)
      ..lineTo(86, 35)
      ..close();

    final rightHorn = Path()
      ..moveTo(138, 45)
      ..lineTo(153, 18)
      ..lineTo(124, 35)
      ..close();

    canvas.drawPath(leftHorn, gold);
    canvas.drawPath(leftHorn, stroke);
    canvas.drawPath(rightHorn, gold);
    canvas.drawPath(rightHorn, stroke);

    // Crown
    final crown = Path()
      ..moveTo(77, 31)
      ..lineTo(86, 8)
      ..lineTo(99, 29)
      ..lineTo(105, 4)
      ..lineTo(112, 29)
      ..lineTo(125, 8)
      ..lineTo(134, 31)
      ..lineTo(128, 46)
      ..lineTo(83, 46)
      ..close();

   
    canvas.drawPath(crown, gold);
    canvas.drawPath(crown, stroke);

    canvas.drawCircle(const Offset(86, 15), 4.5, diamond);
    canvas.drawCircle(const Offset(105, 10), 5, softPink);
    canvas.drawCircle(const Offset(125, 15), 4.5, diamond);
    canvas.drawCircle(const Offset(86, 15), 4.5, stroke);
    canvas.drawCircle(const Offset(105, 10), 5, stroke);
    canvas.drawCircle(const Offset(125, 15), 4.5, stroke);

    // Face
    canvas.drawOval(const Rect.fromLTWH(68, 70, 18, 25), black);
    canvas.drawOval(const Rect.fromLTWH(124, 70, 18, 25), black);

    canvas.drawCircle(const Offset(75, 76), 3.5, white);
    canvas.drawCircle(const Offset(132, 76), 3.5, white);
    canvas.drawCircle(const Offset(79, 86), 2, white);
    canvas.drawCircle(const Offset(136, 86), 2, white);

    final snout = Path()
      ..moveTo(90, 92)
      ..cubicTo(97, 84, 113, 84, 120, 92)
      ..cubicTo(124, 103, 116, 114, 105, 114)
      ..cubicTo(94, 114, 86, 103, 90, 92)
      ..close();

    canvas.drawPath(snout, white);
    canvas.drawPath(snout, stroke);

    canvas.drawOval(const Rect.fromLTWH(100, 96, 10, 7), black);

    final smile = Path()
      ..moveTo(105, 103)
      ..quadraticBezierTo(98, 110, 91, 104)
      ..moveTo(105, 103)
      ..quadraticBezierTo(112, 110, 119, 104);

    canvas.drawPath(smile, stroke);

    canvas.drawCircle(const Offset(61, 99), 6, softPink);
    canvas.drawCircle(const Offset(149, 99), 6, softPink);

    // Arms
    canvas.drawLine(const Offset(55, 113), const Offset(31, 104), stroke);
    canvas.drawLine(const Offset(155, 113), const Offset(179, 104), stroke);

    canvas.drawCircle(const Offset(29, 103), 8, white);
    canvas.drawCircle(const Offset(181, 103), 8, white);
    canvas.drawCircle(const Offset(29, 103), 8, stroke);
    canvas.drawCircle(const Offset(181, 103), 8, stroke);

    // Luxury coin/diamond in hand
    final handDiamond = Path()
      ..moveTo(29, 84)
      ..lineTo(42, 98)
      ..lineTo(29, 114)
      ..lineTo(16, 98)
      ..close();

    canvas.drawPath(handDiamond, diamond);
    canvas.drawPath(handDiamond, stroke);
    canvas.drawLine(const Offset(16, 98), const Offset(42, 98), stroke);
    canvas.drawLine(const Offset(29, 84), const Offset(29, 114), stroke);

    canvas.drawCircle(const Offset(181, 84), 14, orangeGold);
    canvas.drawCircle(const Offset(181, 84), 14, stroke);
    canvas.drawCircle(const Offset(181, 84), 7, gold);
    canvas.drawCircle(const Offset(181, 84), 7, stroke);

    // Chest sparkle
    _drawStar(canvas, const Offset(105, 123), 8, white, stroke);
    _drawStar(canvas, const Offset(119, 132), 4.5, gold, stroke);
    _drawStar(canvas, const Offset(92, 133), 4.5, gold, stroke);

    // Small claws
    canvas.drawLine(const Offset(63, 162), const Offset(58, 166), stroke);
    canvas.drawLine(const Offset(70, 164), const Offset(66, 169), stroke);
    canvas.drawLine(const Offset(139, 164), const Offset(144, 169), stroke);
    canvas.drawLine(const Offset(147, 162), const Offset(152, 166), stroke);

    canvas.restore();
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? radius : radius * 0.42;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
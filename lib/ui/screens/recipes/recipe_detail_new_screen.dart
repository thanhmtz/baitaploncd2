import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/recipe_model.dart';
import 'package:health_tracker/data/repositories/firestore.dart';
import 'package:health_tracker/ui/screens/diary/nutrition/add_meal_screen.dart';

class NewRecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const NewRecipeDetailScreen({Key? key, required this.recipe})
      : super(key: key);

  @override
  State<NewRecipeDetailScreen> createState() => _NewRecipeDetailScreenState();
}

class _NewRecipeDetailScreenState extends State<NewRecipeDetailScreen> {
  bool _isBookmarked = false;
  double _avgRating = 0;
  int _reviewCount = 0;
  double? _userRating;
  bool _loadingRating = true;

  static const Color _green = Color(0xFF2ECC87);

  String? get _networkImageUrl {
    const localMap = {
      1: 'assets/images/hh/images.jpeg',
      2: 'assets/images/hh/tải xuống.webp',
      3: 'assets/images/hh/tải xuống (1).webp',
      4: 'assets/images/hh/tải xuống (2).webp',
      5: 'assets/images/hh/tải xuống (3).webp',
    };
    final local = localMap[widget.recipe.id];
    if (local != null) return local;
    final url = widget.recipe.imageUrl;
    if (url.startsWith('http://localhost')) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('assets/')) return url;
    return null;
  }
  static const Color _greenDark = Color(0xFF1A7A52);
  static const Color _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final recipeId = widget.recipe.id.toString();
    final crud = FireStoreCrud();
    final ratingData = await crud.getRecipeRating(recipeId);
    final userRating = await crud.getUserRecipeRating(recipeId);
    if (mounted) {
      setState(() {
        _avgRating = (ratingData['rating'] as num?)?.toDouble() ?? 0;
        _reviewCount = (ratingData['reviewCount'] as num?)?.toInt() ?? 0;
        _userRating = userRating;
        _loadingRating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaAndTitle(isDark),
                  const SizedBox(height: 20),
                  _buildInfoGrid(isDark),
                  const SizedBox(height: 24),
                  _buildNutritionSection(isDark),
                  const SizedBox(height: 24),
                  _buildIngredientsSection(isDark),
                  const SizedBox(height: 24),
                  _buildStepsSection(isDark),
                  const SizedBox(height: 24),
                  _buildRatingCard(isDark),
                  const SizedBox(height: 16),
                  _buildLogButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, bool isDark) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius:
          const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            // gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x30000000), Colors.transparent],
                ),
              ),
            ),
            // top bar
            Positioned(
              top: top + 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _heroIconBtn(Icons.arrow_back_rounded,
                      () => Navigator.pop(context), 'Quay lại'),
                  Row(
                    children: [
                      _heroIconBtn(
                        _isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        () => setState(() => _isBookmarked = !_isBookmarked),
                        'Lưu',
                      ),
                      const SizedBox(width: 8),
                      _heroIconBtn(
                          Icons.share_outlined, () {}, 'Chia sẻ'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final url = widget.recipe.imageUrl;
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 60, color: Colors.grey),
      ),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Container(color: Colors.grey.shade200),
    );
  }

  Widget _heroIconBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ─── META + TITLE ────────────────────────────────────────────────────────────

  Widget _buildMetaAndTitle(bool isDark) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? Colors.white60 : const Color(0xFF5A6478);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating + tags row
        Row(
          children: [
            const Icon(Icons.star_rounded, color: _amber, size: 16),
            const SizedBox(width: 4),
            Text(
              _loadingRating ? '...' : _avgRating.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
            ),
            const SizedBox(width: 10),
            _buildTag('Bữa sáng', isDark),
            const SizedBox(width: 6),
            _buildTag('Tốt cho tim', isDark),
          ],
        ),
        const SizedBox(height: 8),
        // Title
        Text(
          widget.recipe.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        // Description
        Text(
          widget.recipe.description.isNotEmpty
              ? widget.recipe.description.replaceAll(RegExp(r'<[^>]*>'), '')
              : 'Nhận tất cả hương vị thơm ngon trong một bát yến mạch trái cây và hạt. Ngọt, giòn, ấm áp và ấm cúng!',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            height: 1.6,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _greenDark,
        ),
      ),
    );
  }

  // ─── INFO GRID ───────────────────────────────────────────────────────────────

  Widget _buildInfoGrid(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final greenCardBg = _green.withOpacity(0.12);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);

    final items = [
      {'icon': Icons.local_fire_department_outlined, 'value': '417 Kcal', 'label': 'Calo', 'green': false},
      {'icon': Icons.timer_outlined, 'value': '${widget.recipe.cookingTime} Min', 'label': 'Thời gian', 'green': true},
      {'icon': Icons.restaurant_outlined, 'value': '${widget.recipe.servings} lát', 'label': 'Phần khẩu phần', 'green': false},
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final isGreen = item['green'] as bool;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isGreen ? greenCardBg : cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGreen
                    ? _green.withOpacity(0.25)
                    : borderColor,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(item['icon'] as IconData, size: 20, color: _green),
                const SizedBox(height: 6),
                Text(
                  item['value'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF9BA3B4),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── NUTRITION ───────────────────────────────────────────────────────────────

  Widget _buildNutritionSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textMuted =
        isDark ? Colors.white38 : const Color(0xFF9BA3B4);

    final nutrItems = [
      {'val': '417 Kcal', 'lbl': 'Calo'},
      {'val': '69 g', 'lbl': 'Chất bột'},
      {'val': '8 g', 'lbl': 'Protein'},
      {'val': '15 g', 'lbl': 'Mỡ'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Dinh dưỡng (1 phần)', isDark),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: nutrItems.asMap().entries.map((e) {
              final isLast = e.key == nutrItems.length - 1;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  decoration: isLast
                      ? null
                      : BoxDecoration(
                          border: Border(
                            right: BorderSide(color: borderColor, width: 0.5),
                          ),
                        ),
                  child: Column(
                    children: [
                      Text(
                        e.value['val']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.value['lbl']!,
                        style: TextStyle(fontSize: 11, color: textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── INGREDIENTS ─────────────────────────────────────────────────────────────

  Widget _buildIngredientsSection(bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);

    final ingredients = widget.recipe.ingredients;
    final displayList = ingredients.isEmpty
        ? ['0,5 quả táo', '0,5 muỗng cà phê bơ', '0,25 muỗng cà phê quế',
            '0,13 muỗng cà phê đinh hương', '240 ml nước', '80 g yến mạch',
            '30 g quả nam việt quất khô', '0,13 muỗng cà phê muối',
            '15 g quả óc chó cắt nhỏ', '1 muỗng canh xi-rô cây phong']
        : ingredients.map<String>((ing) {
            if (ing is Map) {
              final name = ing['name'] ?? ing['originalName'] ?? '';
              final amount = ing['amount'] ?? '';
              final unit = ing['unit'] ?? '';
              return '$amount $unit $name'.trim();
            }
            return ing.toString();
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Nguyên liệu', isDark),
        const SizedBox(height: 12),
        ...displayList.asMap().entries.map((e) {
          final isLast = e.key == displayList.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── STEPS ───────────────────────────────────────────────────────────────────

  Widget _buildStepsSection(bool isDark) {
    final textSecondary =
        isDark ? Colors.white60 : const Color(0xFF5A6478);

    final steps = widget.recipe.preparation;
    List<String> stepTexts = [];

    if (steps.isEmpty) {
      stepTexts = [
        'Cắt táo thành miếng ½ inch. Cho khoảng ¾ miếng táo vào nồi nhỏ cùng với bơ, quế và đinh hương. Xào trên lửa vừa trong vài phút.',
        'Thêm nước vào nồi. Đậy nắp lên trên, vặn lửa ở mức trung bình cao và để nước sôi.',
        'Khi nước sôi, cho yến mạch, quả nam việt quất khô và muối vào khuấy đều. Giảm lửa và đun khoảng 5 phút cho đến khi yến mạch đặc lại.',
        'Cho quả óc chó cắt nhỏ và xi-rô phong vào khuấy đều. Nếm thử và điều chỉnh độ ngọt. Top với táo cắt nhỏ còn lại. Ăn nóng.',
      ];
    } else {
      for (final step in steps) {
        if (step is Map) {
          final instructions = step['steps'] ?? [];
          for (final s in instructions) {
            if (s is Map) {
              stepTexts.add(s['step'] ?? '');
            } else {
              stepTexts.add(s.toString());
            }
          }
        }
      }
    }

    final filtered = stepTexts.where((t) => t.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cách nấu ăn', isDark),
        const SizedBox(height: 12),
        ...filtered.asMap().entries.map((e) {
          final isLast = e.key == filtered.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // dot + line column
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: 3),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bước ${e.key + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── RATING CARD ─────────────────────────────────────────────────────────────

  Widget _buildRatingCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);
    final textMuted = isDark ? Colors.white38 : const Color(0xFF9BA3B4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đánh giá của bạn',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = (i + 1).toDouble();
              final filled = _userRating != null && star <= _userRating!;
              return GestureDetector(
                onTap: () async {
                  setState(() => _userRating = star);
                  await FireStoreCrud()
                      .rateRecipe(widget.recipe.id.toString(), star);
                  await _loadRating();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 30,
                    color: filled ? _amber : (isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── TOAST ───────────────────────────────────────────────────────────────────

  void _showToast(String text) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
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
                      color: _green.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withOpacity(0.35),
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
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
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

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  // ─── LOG BUTTON ──────────────────────────────────────────────────────────────

  Widget _buildLogButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await FireStoreCrud().updateDiaryMeal(
            'Lunch',
            widget.recipe.id.toString(),
            'recipe',
            widget.recipe.title,
            417.0,
            69.0,
            15.0,
            8.0,
            imageUrl: _networkImageUrl,
          );

          await FireStoreCrud().addMyDish(
            name: widget.recipe.title,
            calories: 417.0,
            protein: 8.0,
            carbs: 69.0,
            fat: 15.0,
            imageUrl: _networkImageUrl,
            recipeId: widget.recipe.id.toString(),
            mealType: 'Lunch',
            diaryFoodId: widget.recipe.id.toString(),
          );

          if (!context.mounted) return;
          _showToast('Đã thêm món ăn vào nhật ký');

          await Future.delayed(const Duration(milliseconds: 1500));

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMealScreen(title: 'Lunch'),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ghi vào nhật ký',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF0D1117),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/article_model.dart';
import 'package:health_tracker/data/repositories/article_api.dart';
import 'package:health_tracker/shared/styles/animations.dart';
import 'package:health_tracker/shared/widgets/scale_tap.dart';
import 'package:health_tracker/ui/screens/articles/article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  final String category;

  const ArticleListScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<ArticleListScreen> createState() => ArticleListScreenState();
}

class ArticleListScreenState extends State<ArticleListScreen>
    with SingleTickerProviderStateMixin {
  List<Article> _articles = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final api = ArticleApiService();
      final articles = await api.getArticlesByCategory(widget.category);
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _title {
    const names = {
      'tim_mach': 'Tim mạch',
      'giac_ngu': 'Giấc ngủ',
      'dinh_duong': 'Dinh dưỡng',
      'nuoc': 'Nước',
      'calo': 'Calo',
      'tap_luyen': 'Tập luyện',
      'cang_thang': 'Căng thẳng',
    };
    return names[widget.category] ?? widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          _title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF2DBB7A),
              ),
            )
          : _articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài viết nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      return _ArticleCard(
                        article: _articles[index],
                        index: index,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlideRoute(
                              page:
                                  ArticleDetailScreen(article: _articles[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

ImageProvider _imageProvider(String url) {
  if (url.startsWith('http')) return NetworkImage(url);
  return AssetImage(url);
}

class _ArticleCard extends StatefulWidget {
  final Article article;
  final int index;
  final VoidCallback onTap;

  const _ArticleCard({
    Key? key,
    required this.article,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(curve);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? Colors.grey.shade900 : Colors.white;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ScaleTap(
            scale: 0.97,
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.article.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.article.author ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.schedule,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.article.publishedAt ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.article.tags != null &&
                                  widget.article.tags!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: widget.article.tags!
                                        .take(3)
                                        .map((tag) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFF2DBB7A)
                                                        .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2DBB7A),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 110,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _imageProvider(widget.article.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

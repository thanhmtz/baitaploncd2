import 'package:flutter/material.dart';
import 'package:health_tracker/data/repositories/openai_service.dart';

class AssessmentOption {
  final String text;
  final int score;

  const AssessmentOption({required this.text, required this.score});
}

class AssessmentQuestion {
  final String question;
  final List<AssessmentOption> options;

  const AssessmentQuestion({required this.question, required this.options});
}

class AssessmentCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String purpose;
  final int estimatedMinutes;
  final List<AssessmentQuestion> questions;
  final String suggestionTitle;
  final String suggestionBody;
  final String? imageAsset;

  const AssessmentCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.purpose,
    required this.estimatedMinutes,
    required this.questions,
    this.suggestionTitle = '',
    this.suggestionBody = '',
    this.imageAsset,
  });
}

class HealthAssessmentScreen extends StatefulWidget {
  final String title;
  final String? imageAsset;
  final List<AssessmentCategory> categories;

  const HealthAssessmentScreen({
    super.key,
    required this.title,
    this.imageAsset,
    required this.categories,
  });

  @override
  State<HealthAssessmentScreen> createState() => _HealthAssessmentScreenState();
}

class _HealthAssessmentScreenState extends State<HealthAssessmentScreen> with SingleTickerProviderStateMixin {
  int _currentCategoryIndex = 0;
  int _currentQuestionIndex = 0;
  Map<String, int> _answers = {};
  bool _showResult = false;
  bool _animateBack = false;
  bool _isTransitioning = false;
  AIInsight? _aiInsight;
  bool _aiLoading = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _backSlideAnimation;

  List<AssessmentCategory> get _categories => widget.categories;

  AssessmentCategory get _currentCategory => _categories[_currentCategoryIndex];

  AssessmentQuestion get _currentQuestion =>
      _currentCategory.questions[_currentQuestionIndex];

  int get _totalQuestions {
    int count = 0;
    for (var cat in _categories) {
      count += cat.questions.length;
    }
    return count;
  }

  int get _answeredCount => _answers.length;

  int get _currentQuestionNumber {
    int count = 0;
    for (int i = 0; i < _currentCategoryIndex; i++) {
      count += _categories[i].questions.length;
    }
    return count + _currentQuestionIndex;
  }

  bool get _isFirstQuestion =>
      _currentCategoryIndex == 0 && _currentQuestionIndex == 0;

  bool get _isLastQuestion {
    return _currentCategoryIndex == _categories.length - 1 &&
        _currentQuestionIndex == _currentCategory.questions.length - 1;
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _backSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastQuestion) {
      setState(() {
        _isTransitioning = false;
        _showResult = true;
      });
      _fetchAIInsight();
      return;
    }
    _slideController.reverse().then((_) {
      setState(() {
        if (_currentQuestionIndex < _currentCategory.questions.length - 1) {
          _currentQuestionIndex++;
        } else {
          _currentCategoryIndex++;
          _currentQuestionIndex = 0;
        }
        _isTransitioning = false;
      });
      _slideController.forward();
    });
  }

  void _previous() {
    if (_isFirstQuestion) return;
    _animateBack = true;
    _slideController.reverse().then((_) {
      setState(() {
        if (_currentQuestionIndex > 0) {
          _currentQuestionIndex--;
        } else {
          _currentCategoryIndex--;
          _currentQuestionIndex =
              _categories[_currentCategoryIndex].questions.length - 1;
        }
        _isTransitioning = false;
      });
      _animateBack = false;
      _slideController.forward();
    });
  }

  void _selectOption(int score) {
    final key = '$_currentCategoryIndex-$_currentQuestionIndex';
    _answers[key] = score;
  }

  int? _getSelected() {
    final key = '$_currentCategoryIndex-$_currentQuestionIndex';
    return _answers[key];
  }

  Map<String, int> _calculateCategoryScores() {
    Map<String, int> scores = {};
    for (int c = 0; c < _categories.length; c++) {
      int total = 0;
      for (int q = 0; q < _categories[c].questions.length; q++) {
        final key = '$c-$q';
        total += _answers[key] ?? 0;
      }
      scores[_categories[c].name] = total;
    }
    return scores;
  }

  int _getMaxScore(AssessmentCategory cat) {
    int max = 0;
    for (var q in cat.questions) {
      int highest = 0;
      for (var o in q.options) {
        if (o.score > highest) highest = o.score;
      }
      max += highest;
    }
    return max;
  }

  double _getPercent(int score, int max) {
    if (max == 0) return 0;
    return score / max;
  }

  String _getStatus(double percent) {
    if (percent >= 0.7) return 'Tốt';
    if (percent >= 0.4) return 'Trung bình';
    return 'Cần cải thiện';
  }

  Color _getStatusColor(double percent) {
    if (percent >= 0.7) return const Color(0xFF2DBB7A);
    if (percent >= 0.4) return const Color(0xFFFFAA44);
    return const Color(0xFFE07050);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _showResult
          ? _buildResult(isDark)
          : _buildAssessmentContent(isDark),
    );
  }

  Widget _buildAssessmentContent(bool isDark) {
    final total = _totalQuestions;
    final currentNum = _currentQuestionNumber;

    return Column(
      children: [
        // Header: question counter + progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Text(
                'Câu hỏi ${currentNum + 1}/$total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween(begin: 0, end: total > 0 ? currentNum / total : 0.0),
                  curve: Curves.easeInOut,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DBB7A)),
                      minHeight: 5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question + options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SlideTransition(
              position: _animateBack ? _backSlideAnimation : _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _currentQuestion.question,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(_currentQuestion.options.length, (i) {
                    final opt = _currentQuestion.options[i];
                    final isSelected = _getSelected() == opt.score;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _isTransitioning
                            ? null
                            : () {
                              setState(() => _selectOption(opt.score));
                              _isTransitioning = true;
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (!mounted) return;
                                _animateBack = false;
                                _next();
                              });
                            },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _currentCategory.color.withOpacity(0.08)
                                : isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? _currentCategory.color.withOpacity(0.5)
                                  : isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? _currentCategory.color
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? _currentCategory.color
                                        : isDark
                                            ? Colors.white.withOpacity(0.25)
                                            : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? _currentCategory.color
                                        : isDark
                                            ? Colors.white.withOpacity(0.85)
                                            : Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Bottom navigation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isFirstQuestion
                      ? () => Navigator.pop(context)
                      : _previous,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Quay lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2DBB7A),
                    side: const BorderSide(color: Color(0xFF2DBB7A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _getSelected() != null ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLastQuestion
                        ? const Color(0xFF2DBB7A)
                        : const Color(0xFF2DBB7A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    disabledBackgroundColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade200,
                  ),
                  child: Text(
                    _isLastQuestion ? 'Xem kết quả' : 'Tiếp theo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(bool isDark) {
    final scores = _calculateCategoryScores();
    final overallPercent = _calculateOverallPercent();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Overall score circle
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2DBB7A), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2DBB7A).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(overallPercent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getStatus(overallPercent),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đánh giá sức khỏe tổng quát',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getOverallSuggestion(overallPercent),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Category scores
          ...List.generate(_categories.length, (i) {
            final cat = _categories[i];
            final score = scores[cat.name] ?? 0;
            final maxScore = _getMaxScore(cat);
            final percent = _getPercent(score, maxScore);
            final status = _getStatus(percent);
            final statusColor = _getStatusColor(percent);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score/$maxScore điểm',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // AI Insight
          ..._buildAIInsight(isDark, scores),

          const SizedBox(height: 16),

          // Suggestions (only show after AI responded)
          if (_aiInsight != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2DBB7A).withOpacity(0.1),
                    const Color(0xFF4ECDC4).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2DBB7A).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Color(0xFF2DBB7A), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Gợi ý cải thiện',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2DBB7A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildSuggestions(scores, isDark),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentCategoryIndex = 0;
                      _currentQuestionIndex = 0;
                      _answers = {};
                      _showResult = false;
                      _isTransitioning = false;
                      _aiInsight = null;
                      _aiLoading = false;
                    });
                    _slideController.forward();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Làm lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2DBB7A),
                    side: const BorderSide(color: Color(0xFF2DBB7A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Về trang chủ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DBB7A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  double _calculateOverallPercent() {
    double totalScore = 0;
    double totalMax = 0;
    for (var cat in _categories) {
      final max = _getMaxScore(cat);
      totalMax += max;
      int catScore = 0;
      for (int q = 0; q < cat.questions.length; q++) {
        final key =
            '${_categories.indexOf(cat)}-$q';
        catScore += _answers[key] ?? 0;
      }
      totalScore += catScore;
    }
    return totalMax > 0 ? totalScore / totalMax : 0;
  }

  void _fetchAIInsight() {
    if (_categories.isEmpty) return;
    final scores = _calculateCategoryScores();
    final maxScores = <String, int>{};
    for (var cat in _categories) {
      maxScores[cat.name] = _getMaxScore(cat);
    }
    setState(() => _aiLoading = true);
    OpenAIService.getWellnessInsight(
      scores: scores,
      maxScores: maxScores,
    ).then((result) {
      if (!mounted) return;
      setState(() {
        _aiInsight = result;
        _aiLoading = false;
      });
    });
  }

  String _getOverallSuggestion(double percent) {
    if (percent >= 0.7) {
      return 'Sức khỏe của bạn đang ở trạng thái tốt. Hãy duy trì thói quen sinh hoạt lành mạnh nhé!';
    } else if (percent >= 0.4) {
      return 'Sức khỏe của bạn ở mức trung bình. Hãy chú ý cải thiện các thói quen để nâng cao sức khỏe.';
    } else {
      return 'Sức khỏe của bạn cần được quan tâm nhiều hơn. Hãy tham khảo các gợi ý bên dưới nhé!';
    }
  }

  List<Widget> _buildSuggestions(Map<String, int> scores, bool isDark) {
    final aiSuggestions = _aiInsight?.categorySuggestions;
    if (aiSuggestions == null || aiSuggestions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _aiInsight == null ? '' : 'AI chưa thể tạo gợi ý cho lần này.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF2DBB7A)),
          ),
        ),
      ];
    }

    final List<Widget> items = [];
    for (var cat in _categories) {
      final suggestion = aiSuggestions[cat.name];
      if (suggestion == null) continue;

      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(cat.icon, color: cat.color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return items;
  }

  List<Widget> _buildAIInsight(bool isDark, Map<String, int> scores) {
    if (_aiLoading) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F9F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF2DBB7A),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI đang phân tích...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (_aiInsight == null) return [];

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7B68EE).withOpacity(0.1),
              const Color(0xFF36B78B).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7B68EE).withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF7B68EE), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'AI Insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B68EE),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _aiInsight!.insight,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class AssessmentIntroScreen extends StatelessWidget {
  final AssessmentCategory category;

  const AssessmentIntroScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
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
            icon: Icon(Icons.arrow_back, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Bài kiểm tra',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Illustration with background image
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(category.imageAsset ?? 'assets/images/ui/2.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withOpacity(0.3),
                      category.color.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF2DBB7A).withOpacity(0.15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline,
                                size: 16, color: Color(0xFF2DBB7A)),
                            const SizedBox(width: 6),
                            Text(
                              '${category.questions.length} Câu hỏi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2DBB7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF4ECDC4).withOpacity(0.15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 16, color: Color(0xFF4ECDC4)),
                            const SizedBox(width: 6),
                            Text(
                              '${category.estimatedMinutes} phút',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4ECDC4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.purpose,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DBB7A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HealthAssessmentScreen(
                              title: category.name,
                              categories: [category],
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Bắt đầu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

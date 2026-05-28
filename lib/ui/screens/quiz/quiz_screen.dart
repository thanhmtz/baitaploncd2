import 'package:flutter/material.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });
}

class QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;
  final String? imageAsset;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    this.imageAsset,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  Map<int, int> _answers = {};
  bool _submitted = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  bool get _isLast => _currentIndex == widget.questions.length - 1;
  bool get _isFirst => _currentIndex == 0;

  void _next() {
    if (!_isLast) {
      _slideController.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _selectedOption = _answers[_currentIndex];
          _submitted = false;
        });
        _slideController.forward();
      });
    }
  }

  void _previous() {
    if (!_isFirst) {
      setState(() {
        _currentIndex--;
        _selectedOption = _answers[_currentIndex];
        _submitted = false;
      });
    }
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOption = index;
      _answers[_currentIndex] = index;
    });
  }

  int get _score {
    int correct = 0;
    _answers.forEach((questionIndex, selectedIndex) {
      if (selectedIndex == widget.questions[questionIndex].correctIndex) {
        correct++;
      }
    });
    return correct;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _submitted && _isLast
          ? _buildResult(isDark)
          : _buildQuizContent(isDark),
    );
  }

  Widget _buildQuizContent(bool isDark) {
    final total = widget.questions.length;
    final progress = (_currentIndex + 1) / total;
    final question = widget.questions[_currentIndex];

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1}/$total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2DBB7A),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2DBB7A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF2DBB7A).withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DBB7A)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image if available
                  if (widget.imageAsset != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        widget.imageAsset!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Question number badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DBB7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Câu hỏi ${_currentIndex + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2DBB7A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Question text
                  Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ...List.generate(question.options.length, (i) {
                    final isSelected = _selectedOption == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectOption(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2DBB7A).withOpacity(0.12)
                                : isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2DBB7A)
                                  : isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF2DBB7A)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2DBB7A)
                                        : isDark
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFF2DBB7A)
                                        : isDark
                                            ? Colors.white.withOpacity(0.85)
                                            : Colors.black87,
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

                  // Submit button (last question)
                  if (_isLast)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedOption != null
                            ? () {
                                setState(() => _submitted = true);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DBB7A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                        child: const Text(
                          'Hoàn thành',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom navigation
        if (!_isLast || (_isLast && _selectedOption == null))
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
                if (!_isFirst)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Quay lại'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2DBB7A),
                        side: const BorderSide(color: Color(0xFF2DBB7A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (!_isFirst) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedOption != null ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DBB7A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                    child: Text(
                      _isLast ? 'Xem kết quả' : 'Tiếp theo',
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
    final total = widget.questions.length;
    final correct = _score;
    final percent = (correct / total * 100).round();
    final passed = percent >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Result circle
          Container(
            width: 140,
            height: 140,
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
                    '$correct/$total',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'đúng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: passed ? const Color(0xFF2DBB7A) : const Color(0xFFE07050),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            passed ? 'Chúc mừng bạn!' : 'Cố gắng hơn nhé!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            passed
                ? 'Bạn đã có kiến thức tốt về chủ đề này.'
                : 'Hãy tìm hiểu thêm để cải thiện kiến thức của bạn.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 32),

          // Question review
          ...List.generate(widget.questions.length, (i) {
            final q = widget.questions[i];
            final selected = _answers[i] ?? -1;
            final isCorrect = selected == q.correctIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF2DBB7A).withOpacity(0.3)
                      : const Color(0xFFE07050).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? const Color(0xFF2DBB7A) : const Color(0xFFE07050),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Câu ${i + 1}: ${q.question}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF2DBB7A).withOpacity(0.1)
                          : const Color(0xFFE07050).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: isCorrect ? const Color(0xFF2DBB7A) : const Color(0xFFE07050),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'Đáp án đúng: ${q.options[q.correctIndex]}'
                                : 'Đáp án sai. Đáp án đúng: ${q.options[q.correctIndex]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCorrect ? const Color(0xFF2DBB7A) : const Color(0xFFE07050),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (q.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      q.explanation,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Retry / Back buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _selectedOption = null;
                      _answers = {};
                      _submitted = false;
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

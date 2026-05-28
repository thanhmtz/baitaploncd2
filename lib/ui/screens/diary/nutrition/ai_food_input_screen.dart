import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:health_tracker/ui/screens/diary/nutrition/ai_food_thinking_screen.dart';

class AIFoodInputScreen extends StatefulWidget {
  final String mealTitle;

  const AIFoodInputScreen({
    super.key,
    required this.mealTitle,
  });

  @override
  State<AIFoodInputScreen> createState() => _AIFoodInputScreenState();
}

class _AIFoodInputScreenState extends State<AIFoodInputScreen> {
  static const Color _green = Color(0xFF58B40B);

  final _controller = TextEditingController();
  final _speech = stt.SpeechToText();

  bool _isListening = false;
  String? _error;

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;
  Color get textColor => Theme.of(context).colorScheme.onSurface;

  Color get subTextColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white38 : const Color(0xFF9BA3B4);
  }

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToThinkingScreen() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mô tả món ăn');
      return;
    }

    setState(() => _error = null);

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AIFoodThinkingScreen(
          mealTitle: widget.mealTitle,
          foodInput: input,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Phân tích món ăn',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _buildInputCard(),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn đã ăn gì?',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập mô tả món ăn, AI sẽ ước tính calories và dinh dưỡng.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'VD: 1 tô phở bò, 1 ly sữa, 2 quả trứng...',
              hintStyle: TextStyle(
                color: subTextColor,
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _goToThinkingScreen,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Phân tích',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _voiceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voiceButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _isListening ? Colors.red.shade400 : _green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );

    if (!available) {
      setState(() => _error = 'Thiết bị không hỗ trợ nhập giọng nói');
      return;
    }

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      localeId: 'vi_VN',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }
}
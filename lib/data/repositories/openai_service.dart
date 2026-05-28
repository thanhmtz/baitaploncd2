import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class OpenAIService {
  static const List<String> _models = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  static Future<AIInsight> getWellnessInsight({
    required Map<String, int> scores,
    required Map<String, int> maxScores,
  }) async {
    final prompt = _buildPrompt(scores, maxScores);
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}],
        },
      ],
      'systemInstruction': {
        'parts': [
          {
            'text': 'Bạn là một wellness assistant chuyên về self-care guidance và mental health insight. '
                'Bạn KHÔNG được chẩn đoán y khoa, kết luận bệnh, hoặc thay thế bác sĩ. '
                'Hãy trả lời bằng tiếng Việt, ấm áp và khích lệ.',
          }
        ],
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
      },
    });

    for (final model in _models) {
      try {
        final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${APIKeys.gemini}');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 429) continue;
        if (response.statusCode == 200) {
          final result = _processResponse(response.body);
          if (result != null) return result;
        }
        return AIInsight(
          insight: _fallbackOverall(),
          categorySuggestions: null,
        );
      } catch (_) {
        continue;
      }
    }

    return AIInsight(
      insight: _fallbackOverall(),
      categorySuggestions: null,
    );
  }

  static AIInsight? _processResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;

      final parsed = _tryParseJson(raw);
      if (parsed != null) {
        final suggestions = <String, String>{};
        if (parsed['suggestions'] is Map) {
          (parsed['suggestions'] as Map).forEach((k, v) {
            suggestions[k.toString()] = v.toString();
          });
        }
        return AIInsight(
          insight: parsed['insight'] as String? ?? raw,
          categorySuggestions: suggestions,
        );
      }

      final extracted = _extractInsightFromPartial(raw);
      if (extracted.isNotEmpty) {
        return AIInsight(insight: extracted, categorySuggestions: null);
      }
    } catch (_) {}
    return null;
  }

  static String _extractInsightFromPartial(String raw) {
    final regex = RegExp(r'"insight"\s*:\s*"((?:[^"\\]|\\.)*)"');
    final match = regex.firstMatch(raw);
    if (match != null) return match.group(1)!;
    return '';
  }

  static Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end > start) {
        try {
          return jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
        } catch (_) {}
      }
      return null;
    }
  }

  static String _buildPrompt(
    Map<String, int> scores,
    Map<String, int> maxScores,
  ) {
    final buffer = StringBuffer('Dưới đây là kết quả đánh giá sức khỏe tinh thần:\n\n');
    final names = <String>[];
    for (final entry in scores.entries) {
      names.add(entry.key);
      final max = maxScores[entry.key] ?? 0;
      final score = entry.value;
      final inverted = max - score;
      final percent = max > 0 ? (inverted / max * 100).toStringAsFixed(0) : '0';
      buffer.writeln('- ${entry.key}: $inverted/$max ($percent%)');
    }
    buffer.writeln('(Lưu ý: điểm càng cao = triệu chứng càng nặng)');
    buffer.writeln();
    buffer.writeln(
      'Hãy phân tích tổng quan (2-3 câu) và đưa lời khuyên cụ thể cho từng mục. '
      'Dùng CHÍNH XÁC các tên sau làm key trong trường "suggestions": '
      '${names.join(", ")}. '
      'Trả về JSON thuần tuý, không markdown, không giải thích, '
      'theo format: {"insight": "...", "suggestions": {}}',
    );
    return buffer.toString();
  }

  static String _fallbackOverall() {
    return 'Hiện tại không thể kết nối AI để phân tích dữ liệu của bạn.';
  }
}

class AIInsight {
  final String insight;
  final Map<String, String>? categorySuggestions;

  const AIInsight({
    required this.insight,
    this.categorySuggestions,
  });
}
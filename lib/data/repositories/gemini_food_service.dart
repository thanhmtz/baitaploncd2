import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class AIFoodResult {
  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String imageKeyword;

  const AIFoodResult({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageKeyword = '',
  });

  double get totalCalories => calories * quantity;
  double get totalProtein => protein * quantity;
  double get totalCarbs => carbs * quantity;
  double get totalFat => fat * quantity;

  String get imageUrl => imageKeyword.isNotEmpty
      ? 'https://img.spoonacular.com/ingredients_100x100/$imageKeyword.jpg'
      : '';

  factory AIFoodResult.fromJson(Map<String, dynamic> json) {
    return AIFoodResult(
      name: (json['name'] as String?)?.trim() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: (json['unit'] as String?)?.trim() ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      imageKeyword: (json['image'] as String?)?.trim() ?? '',
    );
  }
}

class GeminiFoodService {
  static const List<String> _models = [
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
  ];

  static String _buildPrompt(String userInput) {
    return '''Bạn là chuyên gia dinh dưỡng người Việt.
Phân tích mô tả món ăn sau đây và trả về JSON array.

Mỗi object có các field:
- name: tên món ăn (tiếng Việt)
- quantity: số lượng (mặc định 1)
- unit: đơn vị (quả, ly, bát, tô, miếng, lát, phần, hộp, cái, gói, ...)
- calories: kcal cho MỘT đơn vị
- protein, carbs, fat: gram cho MỘT đơn vị
- image: từ khoá tiếng Anh số ít để tra ảnh trên Spoonacular (VD: egg, rice, bread, apple, milk, noodle, beef, chicken, fish, salad, pizza, cake)

Không markdown, CHỈ trả về JSON array.

Ví dụ:
User: 2 quả trứng và 1 ly sữa
Assistant: [{"name":"Trứng gà","quantity":2,"unit":"quả","calories":70,"protein":6,"carbs":0.6,"fat":5,"image":"egg"},{"name":"Sữa tươi","quantity":1,"unit":"ly","calories":120,"protein":4,"carbs":9,"fat":5,"image":"milk"}]

User: 1 tô phở bò
Assistant: [{"name":"Phở bò","quantity":1,"unit":"tô","calories":450,"protein":25,"carbs":50,"fat":12,"image":"noodle"}]

User: nửa bát cơm và 2 miếng cá kho
Assistant: [{"name":"Cơm trắng","quantity":0.5,"unit":"bát","calories":130,"protein":3,"carbs":28,"fat":0.3,"image":"rice"},{"name":"Cá kho","quantity":2,"unit":"miếng","calories":120,"protein":18,"carbs":2,"fat":5,"image":"fish"}]

User: $userInput
Assistant:''';
  }

  static Future<List<AIFoodResult>> analyzeFood(String userInput) async {
    if (userInput.trim().isEmpty) {
      throw Exception('Vui lòng nhập mô tả món ăn');
    }

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': _buildPrompt(userInput)}],
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1024,
      },
    });

    for (final model in _models) {
      try {
        final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${APIKeys.gemini}');

        log('GeminiFood: calling $model');

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 429) {
          log('GeminiFood: rate limited on $model, trying next...');
          continue;
        }

        if (response.statusCode == 403) {
          log('GeminiFood: auth error on $model: ${response.body}');
          continue;
        }

        if (response.statusCode != 200) {
          log('GeminiFood: error ${response.statusCode} on $model: ${response.body}');
          continue;
        }

        final data = jsonDecode(response.body);

        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          final promptFeedback = data['promptFeedback'];
          if (promptFeedback != null) {
            final blockReason = promptFeedback['blockReason'];
            if (blockReason != null) {
              throw Exception('Nội dung bị chặn: $blockReason');
            }
          }
          continue;
        }

        final raw = candidates[0]?['content']?['parts']?[0]?['text'] as String?;
        if (raw == null || raw.trim().isEmpty) {
          final finishReason = candidates[0]?['finishReason'];
          if (finishReason != null && finishReason != 'STOP') {
            throw Exception('AI không hoàn thành: $finishReason');
          }
          continue;
        }

        return _parseResponse(raw.trim());
      } catch (e) {
        if (e is Exception && e.toString().contains('bị chặn')) rethrow;
        log('GeminiFood: model $model failed: $e');
        continue;
      }
    }

    throw Exception('Không thể kết nối AI. Vui lòng kiểm tra API key hoặc thử lại sau.');
  }

  static List<AIFoodResult> _parseResponse(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start == -1 || end <= start) {
      throw FormatException('AI không trả về kết quả dinh dưỡng hợp lệ');
    }

    final jsonStr = raw.substring(start, end + 1);
    final list = jsonDecode(jsonStr) as List<dynamic>;

    if (list.isEmpty) {
      throw FormatException('AI không tìm thấy món ăn nào trong mô tả của bạn');
    }

    final results = list
        .map((e) => AIFoodResult.fromJson(e as Map<String, dynamic>))
        .where((r) => r.name.isNotEmpty)
        .toList();

    if (results.isEmpty) {
      throw FormatException('AI không thể xác định thông tin dinh dưỡng cho món ăn này');
    }

    return results;
  }
}

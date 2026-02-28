// ============================================================
// NutritionAIService - AI Dinh dưỡng thông minh
// Tích hợp Gemini API với intent recognition (INFO/LOG/CHAT)
// Hỗ trợ contextual memory và tự động ghi nhật ký
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/supabase_config.dart';
import 'local_nutrition_chatbot_service.dart';

/// Loại intent của câu hỏi người dùng
enum NutritionIntent {
  /// Hỏi thông tin dinh dưỡng
  info,

  /// Ghi nhật ký bữa ăn
  log,

  /// Trò chuyện thông thường
  chat,
}

/// Dữ liệu ghi nhật ký bữa ăn
class LogData {
  final String foodName;
  final double quantity;
  final String unit;
  final int calories;

  const LogData({
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
  });

  factory LogData.fromJson(Map<String, dynamic> json) {
    return LogData(
      foodName: json['food_name'] as String? ?? 'Món ăn',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'phần',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'food_name': foodName,
        'quantity': quantity,
        'unit': unit,
        'calories': calories,
      };
}

/// Phản hồi từ AI dinh dưỡng
class NutritionAIResponse {
  final String reply;
  final NutritionIntent action;
  final LogData? logData;
  final bool isError;

  const NutritionAIResponse({
    required this.reply,
    required this.action,
    this.logData,
    this.isError = false,
  });

  factory NutritionAIResponse.error(String message) {
    return NutritionAIResponse(
      reply: message,
      action: NutritionIntent.chat,
      isError: true,
    );
  }
}

/// Tin nhắn trong lịch sử hội thoại
class ConversationMessage {
  final String role; // 'user' or 'model'
  final String content;

  const ConversationMessage({required this.role, required this.content});

  Map<String, dynamic> toGeminiPart() => {
        'role': role,
        'parts': [
          {'text': content}
        ],
      };
}

// ─────────────────────────────────────────────────────────────────────────────
/// [NutritionAIService] — AI Dinh dưỡng thông minh với Gemini API
///
/// Phân tích intent người dùng (INFO/LOG/CHAT) và trả về JSON có cấu trúc.
/// Hỗ trợ contextual memory để hiểu ngữ cảnh hội thoại.
// ─────────────────────────────────────────────────────────────────────────────
class NutritionAIService {
  static NutritionAIService? _instance;

  factory NutritionAIService() {
    _instance ??= NutritionAIService._();
    return _instance!;
  }

  NutritionAIService._();

  // Lịch sử hội thoại (contextual memory)
  final List<ConversationMessage> _conversationHistory = [];

  // Giới hạn lịch sử (để tránh token quá dài)
  static const int _maxHistoryLength = 10;

  // Gemini API endpoint
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // System prompt cho AI dinh dưỡng
  static const String _systemPrompt = '''
Bạn là Trợ lý Dinh dưỡng AI độc quyền của ứng dụng Calo-Tracker. Nhiệm vụ của bạn là tư vấn lượng calo, phân tích dinh dưỡng và hỗ trợ người dùng ghi chép nhật ký ăn uống một cách thông minh, tự nhiên và liền mạch nhất.

TÍNH CÁCH VÀ GIỌNG ĐIỆU:
- Thân thiện, khích lệ, chuyên nghiệp và ngắn gọn.
- Luôn theo dõi sát ngữ cảnh của cuộc hội thoại (các món ăn, lượng calo vừa được nhắc đến).

NHIỆM VỤ CỐT LÕI (Intent Recognition):
Phân tích câu nói của người dùng để xác định 1 trong 3 hành động sau:
1. "INFO": Người dùng chỉ đang hỏi thông tin (VD: "1 bát phở bao nhiêu calo?", "Ăn chuối có béo không?").
2. "LOG": Người dùng xác nhận đã ăn/uống món gì đó, hoặc ra lệnh ghi chép (VD: "Tôi vừa ăn nó", "Ghi lại cho tôi 2 bát cơm", "Sáng nay ăn 1 ổ bánh mì"). 
3. "CHAT": Trò chuyện thông thường không liên quan đến calo hoặc thức ăn.

QUY TẮC HIỂU NGỮ CẢNH (Contextual Memory):
- Nếu người dùng dùng các đại từ nhân xưng thay thế ("nó", "cái đó", "món vừa rồi") hoặc nói trống không ("đã ăn 2 cái"), BẮT BUỘC phải đối chiếu với món ăn và định lượng ở câu hỏi ngay trước đó của họ để xác định chính xác thực thể.
- Tự động ước lượng lượng calo chuẩn nếu người dùng không cung cấp số calo cụ thể.

ĐỊNH DẠNG ĐẦU RA (Output Format):
Bạn CHỈ ĐƯỢC PHÉP trả về định dạng JSON thuần túy (không kèm markdown ```json), tuân thủ tuyệt đối cấu trúc sau:
{
  "reply": "Câu trả lời giao tiếp tự nhiên dành cho người dùng",
  "action": "INFO" | "LOG" | "CHAT",
  "log_data": {
    "food_name": "Tên món ăn (nếu action là LOG, ngược lại là null)",
    "quantity": Số lượng (kiểu float, nếu action là LOG, ngược lại là null),
    "unit": "Đơn vị (quả, bát, gram, ml...)",
    "calories": Tổng số kcal ước tính (kiểu int)
  }
}

Nếu action là INFO hoặc CHAT, log_data phải là null.
''';

  /// Lấy Gemini API key từ config
  String? get _apiKey {
    final key = SupabaseConfig.geminiApiKey;
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY') return null;
    return key;
  }

  /// Xóa lịch sử hội thoại
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Xử lý tin nhắn từ người dùng
  Future<NutritionAIResponse> processMessage(String userMessage) async {
    // Thêm tin nhắn người dùng vào lịch sử
    _conversationHistory.add(
      ConversationMessage(role: 'user', content: userMessage),
    );

    // Giới hạn lịch sử
    if (_conversationHistory.length > _maxHistoryLength * 2) {
      _conversationHistory.removeRange(0, 2);
    }

    try {
      final apiKey = _apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        // Fallback to offline mode if no API key
        return await _processOffline(userMessage);
      }

      final response = await _callGeminiAPI(apiKey);
      return response;
    } catch (e) {
      debugPrint('NutritionAI Error: $e');
      // Fallback to offline mode on error
      return await _processOffline(userMessage);
    }
  }

  /// Gọi Gemini API
  Future<NutritionAIResponse> _callGeminiAPI(String apiKey) async {
    final url = Uri.parse('$_geminiBaseUrl?key=$apiKey');

    // Build conversation history for Gemini
    final contents = <Map<String, dynamic>>[];

    // Add system instruction as first user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': _systemPrompt}
      ],
    });
    contents.add({
      'role': 'model',
      'parts': [
        {
          'text':
              '{"reply": "Xin chào! Tôi là trợ lý dinh dưỡng của bạn. Hãy hỏi tôi về calo hoặc ghi nhật ký ăn uống!", "action": "CHAT", "log_data": null}'
        }
      ],
    });

    // Add conversation history
    for (final msg in _conversationHistory) {
      contents.add(msg.toGeminiPart());
    }

    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 512,
        'responseMimeType': 'application/json',
      },
    };

    final httpResponse = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 15));

    if (httpResponse.statusCode != 200) {
      throw Exception('Gemini API error: ${httpResponse.statusCode}');
    }

    final responseJson = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List;
    final text = parts[0]['text'] as String;

    // Parse JSON response
    final parsed = _parseAIResponse(text);

    // Add AI response to history
    _conversationHistory.add(
      ConversationMessage(role: 'model', content: text),
    );

    return parsed;
  }

  /// Parse JSON response từ AI
  NutritionAIResponse _parseAIResponse(String text) {
    try {
      // Clean up the text (remove markdown if any)
      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final json = jsonDecode(cleanText) as Map<String, dynamic>;

      final reply = json['reply'] as String? ?? 'Xin lỗi, tôi không hiểu.';
      final actionStr = json['action'] as String? ?? 'CHAT';
      final logDataJson = json['log_data'] as Map<String, dynamic>?;

      NutritionIntent action;
      switch (actionStr.toUpperCase()) {
        case 'INFO':
          action = NutritionIntent.info;
          break;
        case 'LOG':
          action = NutritionIntent.log;
          break;
        default:
          action = NutritionIntent.chat;
      }

      LogData? logData;
      if (action == NutritionIntent.log && logDataJson != null) {
        logData = LogData.fromJson(logDataJson);
      }

      return NutritionAIResponse(
        reply: reply,
        action: action,
        logData: logData,
      );
    } catch (e) {
      debugPrint('Parse error: $e, text: $text');
      return NutritionAIResponse(
        reply: text,
        action: NutritionIntent.chat,
      );
    }
  }

  /// Xử lý offline khi không có API key
  /// Sử dụng LocalNutritionChatbotService với từ điển 40+ món ăn Việt Nam
  Future<NutritionAIResponse> _processOffline(String message) async {
    final localBot = LocalNutritionChatbotService();
    final localResponse = await localBot.processMessage(message);

    switch (localResponse.intent) {
      case ChatbotIntent.log:
        return NutritionAIResponse(
          reply: localResponse.reply,
          action: NutritionIntent.log,
          logData: localResponse.foodName != null
              ? LogData(
                  foodName: localResponse.foodName!,
                  quantity: (localResponse.quantity ?? 1).toDouble(),
                  unit: 'phần',
                  calories: localResponse.totalKcal ?? 0,
                )
              : null,
        );
      case ChatbotIntent.info:
        return NutritionAIResponse(
          reply: localResponse.reply,
          action: NutritionIntent.info,
        );
      case ChatbotIntent.unknown:
        return NutritionAIResponse(
          reply: localResponse.reply,
          action: NutritionIntent.chat,
        );
    }
  }
}

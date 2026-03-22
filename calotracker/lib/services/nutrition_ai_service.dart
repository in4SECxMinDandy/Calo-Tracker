// ============================================================
// NutritionAIService - AI Dinh dưỡng thông minh
// Tích hợp Gemini API với intent recognition (INFO/LOG/CHAT)
// Hỗ trợ contextual memory và tự động ghi nhật ký
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import 'database_service.dart';
import 'sleep_service.dart';
import 'storage_service.dart';
import 'local_nutrition_chatbot_service.dart';

/// Loại intent của câu hỏi người dùng
enum NutritionIntent {
  /// Hỏi thông tin dinh dưỡng
  info,

  /// Ghi nhật ký bữa ăn
  log,

  /// Ghi nhật ký giấc ngủ
  sleep,

  /// Ghi nhật ký nước uống
  water,

  /// Trò chuyện thông thường
  chat,
}

/// Dữ liệu ghi nhật ký bữa ăn
class LogData {
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const LogData({
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  factory LogData.fromJson(Map<String, dynamic> json) {
    return LogData(
      foodName: json['food_name'] as String? ?? 'Món ăn',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'phần',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein_g'] as num? ?? json['protein'] as num? ?? 0.0).toDouble(),
      carbs: (json['carbs_g'] as num? ?? json['carbs'] as num? ?? 0.0).toDouble(),
      fat: (json['fat_g'] as num? ?? json['fat'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'food_name': foodName,
    'quantity': quantity,
    'unit': unit,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}

/// Dữ liệu ghi nhật ký giấc ngủ
class SleepLogData {
  final double hours;
  final DateTime? bedTime;
  final DateTime? wakeTime;
  final int? quality; // 1-5

  const SleepLogData({
    required this.hours,
    this.bedTime,
    this.wakeTime,
    this.quality,
  });

  factory SleepLogData.fromJson(Map<String, dynamic> json) {
    return SleepLogData(
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      bedTime:
          json['bed_time'] != null
              ? DateTime.tryParse(json['bed_time'] as String)
              : null,
      wakeTime:
          json['wake_time'] != null
              ? DateTime.tryParse(json['wake_time'] as String)
              : null,
      quality: (json['quality'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'hours': hours,
    'bed_time': bedTime?.toIso8601String(),
    'wake_time': wakeTime?.toIso8601String(),
    'quality': quality,
  };
}

/// Phản hồi từ AI dinh dưỡng
class NutritionAIResponse {
  final String reply;
  final NutritionIntent action;
  final LogData? logData;
  final SleepLogData? sleepLogData;
  final int? waterAmount; // ml
  final bool isError;

  const NutritionAIResponse({
    required this.reply,
    required this.action,
    this.logData,
    this.sleepLogData,
    this.waterAmount,
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
      {'text': content},
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

  // Current conversation ID
  String? _currentConversationId;

  // Lịch sử hội thoại (contextual memory)
  final List<ConversationMessage> _conversationHistory = [];

  // Giới hạn lịch sử (để tránh token quá dài)
  static const int _maxHistoryLength = 10;

  /// Get current conversation ID
  String? get currentConversationId => _currentConversationId;

  /// Start a new conversation
  Future<String> startNewConversation() async {
    _conversationHistory.clear();
    _currentConversationId = await DatabaseService.createConversation();
    return _currentConversationId!;
  }

  /// Set current conversation (load existing)
  Future<void> setCurrentConversation(String conversationId) async {
    _currentConversationId = conversationId;
    // Load messages for this conversation into AI context
    final messages = await DatabaseService.getMessagesByConversation(conversationId);
    loadConversationHistory(messages);
  }

  /// Load conversation history from database
  void loadConversationHistory(List<ChatMessage> messages) {
    _conversationHistory.clear();
    for (final msg in messages) {
      _conversationHistory.add(ConversationMessage(
        role: msg.isUser ? 'user' : 'model',
        content: msg.message,
      ));
    }
  }

  // Gemini API endpoint
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // System prompt cho trợ lý sức khỏe AI
  static const String _systemPrompt = '''
Bạn là Trợ lý Sức khỏe AI độc quyền của ứng dụng Calo-Tracker. Nhiệm vụ của bạn là tư vấn dinh dưỡng, giấc ngủ và các chỉ số sức khỏe để giúp người dùng sống lành mạnh hơn.

TÍNH CÁCH VÀ GIỌNG ĐIỆU:
- Thân thiện, khích lệ (luôn cổ vũ người dùng đạt mục tiêu).
- Ngắn gọn, súc tích (không trả lời dài hơn cần thiết).
- Thông minh: Hiểu ngữ cảnh các món ăn hoặc hoạt động vừa nhắc đến.

NHIỆM VỤ CỐT LÕI (Intent Recognition):
Bạn cần xác định 1 trong 5 hành động sau từ câu nói của người dùng:
1. "INFO": Hỏi thông tin (VD: "Phở bao nhiêu calo?", "Ngủ 8 tiếng có tốt không?").
2. "LOG": Ghi nhật ký ăn uống (VD: "Tôi vừa ăn nó", "Thêm 1 bát cơm", "Sáng nay ăn phở").
3. "SLEEP": Ghi nhật ký giấc ngủ (VD: "Tôi đã ngủ 7 tiếng", "Đêm qua ngủ từ 11h đến 6h sáng").
4. "WATER": Ghi nhật ký uống nước (VD: "Tôi vừa uống 250ml nước", "Uống thêm 1 cốc nước").
5. "CHAT": Trò chuyện xã giao hoặc không thuộc các loại trên.

QUY TẮC DINH DƯỠNG:
- Nếu người dùng nói "Tôi vừa ăn nó" sau khi hỏi về phở, hãy xác định đó là món phở.
- Luôn ước lượng calo/macros dựa trên kiến thức dinh dưỡng toàn cầu của bạn.
- KHÔNG bao giờ trả lời "không biết" về dinh dưỡng — hãy ước lượng hợp lý nhất có thể.
- Với món ăn KHÔNG phổ biến ở Việt Nam (pizza, sushi, burger, v.v.), hãy dùng kiến thức dinh dưỡng quốc tế.
- KHÔNG ĐƯỢC luôn trả về 400 calo. Hãy phân tích kỹ và ước lượng thực tế.
- Macros phải khớp với calo: 1g Protein=4kcal, 1g Carb=4kcal, 1g Fat=9kcal.
- Hiện tại là ngày: {{CURRENT_DATE}}.

DỮ LIỆU SỨC KHỎE HÔM NAY CỦA NGƯỜI DÙNG:
{{USER_HEALTH_DATA}}
Hãy sử dụng dữ liệu này để trả lời câu hỏi như "Hôm nay tôi đã ăn bao nhiêu calo?", "Tôi còn có thể ăn thêm bao nhiêu?", "Đêm qua tôi ngủ mấy tiếng?".

ĐỊNH DẠNG ĐẦU RA — CHỈ JSON THUẦN TÚY (không markdown, không giải thích thêm):
{
  "reply": "Câu trả lời ngắn gọn bằng tiếng Việt",
  "action": "INFO",
  "log_data": null,
  "sleep_log_data": null,
  "water_amount": null
}

LƯU Ý QUAN TRỌNG:
- Trường "reply" phải là chuỗi hoàn chỉnh, không được cắt giữa chừng.
- log_data chỉ điền khi action là LOG (gồm đầy đủ protein, carbs, fat).
- sleep_log_data chỉ điền khi action là SLEEP.
- water_amount chỉ điền khi action là WATER (đơn vị ml, ví dụ: 250).
- Các trường không dùng để null.
- Phản hồi phải là JSON hợp lệ, đầy đủ, không bị cắt.
''';

  /// Lấy Gemini API key từ config
  String? get _apiKey {
    final key = SupabaseConfig.geminiApiKey;
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY') {
      return null;
    }
    return key;
  }

  /// Xóa lịch sử hội thoại
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Export lịch sử hội thoại hiện tại (để lưu vào database)
  List<ConversationMessage> get conversationHistory {
    return List.unmodifiable(_conversationHistory);
  }

  /// Đọc dữ liệu sức khỏe hôm nay để đưa vào context AI
  Future<String> _fetchHealthContext() async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Calo intake & burned
      final caloRecord = await DatabaseService.getCaloRecord(dateStr);

      // User profile / daily target
      final UserProfile? profile = StorageService.getUserProfile();
      final double dailyTarget = profile?.dailyTarget ?? 2000;
      final double remaining = (dailyTarget - caloRecord.caloIntake).clamp(0, 9999);

      // Water today
      final int waterMl = await DatabaseService.getTodayWaterTotal();

      // Sleep last night
      final sleepRecord = await SleepService.getLastNightSleepRecord();
      String sleepText = 'Chưa có dữ liệu giấc ngủ';
      if (sleepRecord != null) {
        final hours = sleepRecord.durationHours.toStringAsFixed(1);
        sleepText = '${hours}h (${sleepRecord.bedTimeFormatted} → ${sleepRecord.wakeTimeFormatted})';
      }

      return '''
- Mục tiêu calo/ngày: ${dailyTarget.toInt()} kcal
- Đã nạp hôm nay: ${caloRecord.caloIntake.toInt()} kcal
- Đã đốt hôm nay: ${caloRecord.caloBurned.toInt()} kcal
- Còn lại có thể ăn: ${remaining.toInt()} kcal
- Calo thuần (net): ${caloRecord.netCalo.toInt()} kcal
- Uống nước hôm nay: ${waterMl}ml
- Giấc ngủ đêm qua: $sleepText''';
    } catch (e) {
      debugPrint('Health context fetch error: $e');
      return '(Không thể đọc dữ liệu sức khỏe hôm nay)';
    }
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
    final now = DateTime.now();
    final formattedDate =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
    final healthContext = await _fetchHealthContext();
    final dynamicPrompt = _systemPrompt
        .replaceAll('{{CURRENT_DATE}}', formattedDate)
        .replaceAll('{{USER_HEALTH_DATA}}', healthContext);

    contents.add({
      'role': 'user',
      'parts': [
        {'text': dynamicPrompt},
      ],
    });
    contents.add({
      'role': 'model',
      'parts': [
        {
          'text':
              '{"reply": "Xin chào! Tôi là trợ lý sức khỏe của bạn. Hãy hỏi tôi về dinh dưỡng, giấc ngủ hoặc ghi nhật ký!", "action": "CHAT", "log_data": null, "sleep_log_data": null, "water_amount": null}',
        },
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
        'maxOutputTokens': 2048,
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
    _conversationHistory.add(ConversationMessage(role: 'model', content: text));

    return parsed;
  }

  /// Parse JSON response từ AI
  NutritionAIResponse _parseAIResponse(String text) {
    try {
      // Clean up the text (remove markdown code blocks if any)
      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      // Try to recover truncated JSON by finding the last complete object
      Map<String, dynamic> json;
      try {
        json = jsonDecode(cleanText) as Map<String, dynamic>;
      } catch (parseErr) {
        // Attempt to recover: find the last valid closing brace
        debugPrint('Primary JSON parse failed: $parseErr');
        final recovered = _tryRecoverJson(cleanText);
        if (recovered != null) {
          json = recovered;
        } else {
          // Extract just the reply text if JSON is unrecoverable
          final replyMatch = RegExp(r'"reply"\s*:\s*"([^"]+)"').firstMatch(cleanText);
          final replyText = replyMatch?.group(1) ?? text.replaceAll(RegExp(r'[{}"]'), '').trim();
          return NutritionAIResponse(
            reply: replyText.isNotEmpty ? replyText : 'Xin lỗi, tôi không thể trả lời lúc này.',
            action: NutritionIntent.chat,
          );
        }
      }

      final reply = json['reply'] as String? ?? 'Xin lỗi, tôi không hiểu.';
      final actionStr = json['action'] as String? ?? 'CHAT';
      final logDataJson = json['log_data'] as Map<String, dynamic>?;
      final sleepLogDataJson = json['sleep_log_data'] as Map<String, dynamic>?;
      final waterAmountRaw = json['water_amount'];
      final waterAmount = waterAmountRaw is int
          ? waterAmountRaw
          : (waterAmountRaw is num ? waterAmountRaw.toInt() : null);

      NutritionIntent action;
      switch (actionStr.toUpperCase()) {
        case 'INFO':
          action = NutritionIntent.info;
          break;
        case 'LOG':
          action = NutritionIntent.log;
          break;
        case 'SLEEP':
          action = NutritionIntent.sleep;
          break;
        case 'WATER':
          action = NutritionIntent.water;
          break;
        default:
          action = NutritionIntent.chat;
      }

      LogData? logData;
      if (action == NutritionIntent.log && logDataJson != null) {
        logData = LogData.fromJson(logDataJson);
      }

      SleepLogData? sleepLogData;
      if (action == NutritionIntent.sleep && sleepLogDataJson != null) {
        sleepLogData = SleepLogData.fromJson(sleepLogDataJson);
      }

      return NutritionAIResponse(
        reply: reply,
        action: action,
        logData: logData,
        sleepLogData: sleepLogData,
        waterAmount: waterAmount,
      );
    } catch (e) {
      debugPrint('Parse error: $e, text: $text');
      // Last resort: return raw text as a chat message
      final safeReply = text.length > 300 ? '${text.substring(0, 300)}...' : text;
      return NutritionAIResponse(reply: safeReply, action: NutritionIntent.chat);
    }
  }

  /// Cố gắng phục hồi JSON bị cắt ngắn bằng cách thêm dấu đóng ngoặc
  Map<String, dynamic>? _tryRecoverJson(String text) {
    // Count unmatched braces and try to close them
    int depth = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == r'\\') {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (ch == '{') { depth++; }
        else if (ch == '}') { depth--; }
      }
    }

    if (depth <= 0) return null; // Already closed or badly malformed

    // Close open string if needed, then close braces
    String recovered = text;
    if (inString) recovered += '"'; // Close unterminated string
    recovered += '}' * depth;

    try {
      return jsonDecode(recovered) as Map<String, dynamic>;
    } catch (_) {
      return null;
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
          logData:
              localResponse.foodName != null
                  ? LogData(
                    foodName: localResponse.foodName!,
                    quantity: (localResponse.quantity ?? 1).toDouble(),
                    unit: 'phần',
                    calories: (localResponse.totalKcal ?? 0).toDouble(),
                  )
                  : null,
        );
      case ChatbotIntent.info:
        return NutritionAIResponse(
          reply: localResponse.reply,
          action: NutritionIntent.info,
        );
      case ChatbotIntent.unknown:
        final lower = message.toLowerCase();
        if (lower.contains('uống nước') || lower.contains('uống thêm')) {
           // Basic water recognition offline
           RegExp reg = RegExp(r'(\d+)');
           var match = reg.firstMatch(message);
           int amount = match != null ? int.parse(match.group(1)!) : 250;
           return NutritionAIResponse(
             reply: 'Đã ghi nhận bạn uống ${amount}ml nước.',
             action: NutritionIntent.water,
             waterAmount: amount,
           );
        }
        return NutritionAIResponse(
          reply: localResponse.reply,
          action: NutritionIntent.chat,
        );
    }
  }
}

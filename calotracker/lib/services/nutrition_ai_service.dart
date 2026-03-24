// ============================================================
// NutritionAIService - AI Dinh dưỡng thông minh
// Tích hợp Gemini API với intent recognition (INFO/LOG/CHAT)
// Hỗ trợ contextual memory và tự động ghi nhật ký
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import 'database_service.dart';
import 'sleep_service.dart';
import 'storage_service.dart';
import 'meal_suggestion_service.dart';

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

  /// Gợi ý món ăn dựa trên kcal còn lại
  suggest,

  /// Trò chuyện thông thường
  chat,
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

/// Chuẩn hóa map từ JSON (kể cả key không phải String) để parse log_data an toàn.
Map<String, dynamic>? _asStringKeyMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
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
      quantity: _parseDouble(json['quantity'], 1.0),
      unit: json['unit'] as String? ?? 'phần',
      calories: _parseDouble(json['calories']),
      protein: _parseDouble(json['protein_g'] ?? json['protein']),
      carbs: _parseDouble(json['carbs_g'] ?? json['carbs']),
      fat: _parseDouble(json['fat_g'] ?? json['fat']),
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
      hours: _parseDouble(json['hours']),
      bedTime:
          json['bed_time'] != null
              ? DateTime.tryParse(json['bed_time'] as String)
              : null,
      wakeTime:
          json['wake_time'] != null
              ? DateTime.tryParse(json['wake_time'] as String)
              : null,
      quality: _parseInt(json['quality'], 3),
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
  final List<MealSuggestion>? suggestions; // gợi ý món ăn
  final bool isError;

  const NutritionAIResponse({
    required this.reply,
    required this.action,
    this.logData,
    this.sleepLogData,
    this.waterAmount,
    this.suggestions,
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
  final String role; // 'user' or 'assistant'
  final String content;

  const ConversationMessage({required this.role, required this.content});

  Map<String, dynamic> toAnthropicPart() => {'role': role, 'content': content};
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
    final messages = await DatabaseService.getMessagesByConversation(
      conversationId,
    );
    loadConversationHistory(messages);
  }

  /// Load conversation history from database
  void loadConversationHistory(List<ChatMessage> messages) {
    _conversationHistory.clear();
    for (final msg in messages) {
      _conversationHistory.add(
        ConversationMessage(
          role: msg.isUser ? 'user' : 'assistant',
          content: msg.message,
        ),
      );
    }
  }

  // Anthropic API configuration
  static const String _anthropicBaseUrl =
      'https://taphoaapi.info.vn/v1/messages';
  static const String _apiKeyStr = 'sk-proj-69981a1c7a6c4bb3ad6f5c34f274cadd';

  /// Proxy + JSON dài (SUGGEST nhiều món) thường >15s; 15s gây TimeoutException.
  static const Duration _httpTimeout = Duration(seconds: 60);

  // System prompt cho trợ lý sức khỏe AI
  static const String _systemPrompt = '''
[ĐẦU RA — BẮT BUỘC — ĐỌC TRƯỚC]
Bạn đang nói chuyện với MÁY (API), không phải hiển thị cho người dùng trực tiếp.
- Mỗi lần trả lời: CHỈ một object JSON. Ký tự đầu tiên của phần bạn sinh ra (sau dấu { đã gửi sẵn) phải là dấu " (mở trường "reply").
- CẤM: # ## ### | bảng | ``` | emoji đầu dòng | Markdown | tiêu đề.
- Tin nhắn assistant trong lịch sử là bản hiển thị cũ; LẦN NÀY vẫn phải trả JSON cho app.

Bạn là Trợ lý Sức khỏe AI của Calo-Tracker (tư vấn dinh dưỡng, giấc ngủ).

ĐỊNH DẠNG JSON (một dòng hoặc nhiều dòng nhưng HỢP LỆ):
- BẮT BUỘC TRẢ VỀ CHÍNH XÁC 6 KHÓA NÀY MỌI LÚC (dùng null nếu không áp dụng): "reply", "action", "log_data", "sleep_log_data", "water_amount", "suggestions"
- "reply": một chuỗi ngắn (tiếng Việt), có thể dùng \\n trong chuỗi cho xuống dòng
- Không thêm văn bản ngoài object JSON

XÁC ĐỊNH INTENT — action phải là một trong (INFO|LOG|SLEEP|WATER|SUGGEST|CHAT):
1. INFO: Hỏi thông tin dinh dưỡng/giấc ngủ (VD: "phở bao nhiêu calo?", "ngủ 8 tiếng tốt không?")
2. LOG: Ghi nhật ký ăn uống (VD: "tôi ăn 2 quả trứng", "vừa ăn phở", "thêm 1 bát cơm")
3. SLEEP: Ghi nhật ký giấc ngủ (VD: "ngủ 7 tiếng", "đêm qua 11h đến 6h", "tôi ngủ 30 phút")
4. WATER: Ghi nhật ký uống nước (VD: "uống 250ml", "thêm 1 cốc nước", "tôi uống 500ml")
5. SUGGEST: Gợi ý món ăn (VD: "gợi ý món ăn", "hôm nay ăn gì", "còn X kcal")
6. CHAT: Trò chuyện thông thường

BẤT CỨ KHI NÀO người dùng thông báo họ VỪA MỚI/ĐÃ ăn món gì, uống nước, hoặc ngủ (ví dụ: "tôi vừa ăn 2 quả trứng", "uống 500ml", "ngủ 30 phút"), BẮT BUỘC action phải là LOG, WATER, hoặc SLEEP tương ứng.
TUYỆT ĐỐI KHÔNG dùng action=CHAT hoặc INFO thay vì khai báo ghi nhận.
Nếu bạn nói "Đã ghi nhận/cập nhật" trong reply, bạn BẮT BUỘC cung cấp "log_data", "water_amount", hoặc "sleep_log_data" đầy đủ.
Ứng dụng sẽ KHÔNG thể lưu dữ liệu nếu các trường này bị null!

QUY TẮC DỮ LIỆU:
- Sử dụng dữ liệu từ [NGỮ CẢNH SỨC KHỎE] đã được cung cấp
- KHÔNG nói "không có thông tin" - tất cả đã có sẵn
- KHÔNG hỏi lại người dùng về chiều cao, cân nặng, tuổi, mục tiêu
- Khi hỏi calo còn lại → đọc dòng "Còn lại có thể ăn" trong ngữ cảnh

QUY TẮC DINH DƯỠNG:
- Ước lượng calo/macros dựa trên kiến thức dinh dưỡng Việt Nam
- Với món Việt Nam: phở (~450kcal/bát), cơm (~200kcal/bát), trứng luộc (~78kcal/quả)
- Macros phải khớp: Protein×4 + Carbs×4 + Fat×9 = Calories
- KHÔNG bao giờ trả về "không biết"

VÍ DỤ ĐỊNH DẠNG ĐÚNG (copy chính xác format này):
{"reply": "1 bát phở bò có khoảng 450-500 kcal. Bạn đã nạp 1200 kcal hôm nay, còn 800 kcal.", "action": "INFO", "log_data": null, "sleep_log_data": null, "water_amount": null, "suggestions": null}
{"reply": "Đã ghi nhận: 1 quả trứng luộc = 78 kcal", "action": "LOG", "log_data": {"food_name": "Trứng luộc", "quantity": 1, "unit": "quả", "calories": 78, "protein_g": 6, "carbs_g": 1, "fat_g": 5}, "sleep_log_data": null, "water_amount": null, "suggestions": null}
{"reply": "Gợi ý bữa tối với 500 kcal còn lại", "action": "SUGGEST", "log_data": null, "sleep_log_data": null, "water_amount": null, "suggestions": [{"name": "Cơm gà", "description": "Cơm với ức gà hấp", "calories": 480, "protein": 35, "carbs": 55, "fat": 12, "reason": "Protein cao, phù hợp bữa tối"}]}
{"reply": "Đã ghi nhận: ngủ 7 tiếng", "action": "SLEEP", "log_data": null, "sleep_log_data": {"hours": 7, "quality": 3}, "water_amount": null, "suggestions": null}
{"reply": "Đã ghi nhận: uống 250ml nước", "action": "WATER", "log_data": null, "sleep_log_data": null, "water_amount": 250, "suggestions": null}

log_data (khi action=LOG): bắt buộc food_name, quantity, unit, calories, protein_g, carbs_g, fat_g
suggestions[] (khi action=SUGGEST): name, description, calories, protein, carbs, fat, reason (số macro là số g, không dùng bảng markdown)
Ngày: {{CURRENT_DATE}}
''';

  /// Lấy API key
  String? get _apiKey {
    return _apiKeyStr;
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
          '${today.year}-${today.month.toString().padLeft(2, "0")}-${today.day.toString().padLeft(2, "0")}';

      // Calo intake & burned
      final caloRecord = await DatabaseService.getCaloRecord(dateStr);

      // User profile / daily target
      final UserProfile? profile = StorageService.getUserProfile();
      final double dailyTarget = profile?.dailyTarget ?? 2000;
      final double remaining = (dailyTarget - caloRecord.caloIntake).clamp(
        0,
        9999,
      );

      // Water today
      final int waterMl = await DatabaseService.getTodayWaterTotal();

      // Sleep last night
      final sleepRecord = await SleepService.getLastNightSleepRecord();
      String sleepText = 'Chưa có dữ liệu giấc ngủ';
      if (sleepRecord != null) {
        final hours = sleepRecord.durationHours.toStringAsFixed(1);
        sleepText =
            '${hours}h (${sleepRecord.bedTimeFormatted} → ${sleepRecord.wakeTimeFormatted})';
      }

      // Build profile section
      String profileSection = '(Chưa có hồ sơ cá nhân)';
      if (profile != null) {
        final goalText =
            profile.goal == 'lose'
                ? 'Giảm cân'
                : profile.goal == 'gain'
                ? 'Tăng cân'
                : 'Duy trì cân nặng';
        final genderText = profile.gender.value == 'male' ? 'Nam' : 'Nữ';
        profileSection = '''
- Tên: ${profile.name}
- Tuổi: ${profile.age} tuổi
- Giới tính: $genderText
- Chiều cao: ${profile.height.toInt()} cm
- Cân nặng hiện tại: ${profile.weight.toStringAsFixed(1)} kg
- Chỉ số BMR (trao đổi chất cơ bản): ${profile.bmr.toInt()} kcal/ngày
- Mục tiêu sức khoẻ: $goalText
- Mục tiêu calo/ngày: ${dailyTarget.toInt()} kcal''';
      }

      return '''
=== HỒ SƠ CÁ NHÂN ===
$profileSection

=== HOẠT ĐỘNG HÔM NAY ===
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

  /// Nhúng health data trực tiếp vào user message.
  /// Đây là biện pháp dự phòng: đảm bảo model luôn thấy dữ liệu
  /// bất kể proxy API có strip trường 'system' hay không.
  String _buildContextualUserMessage(
    String originalMessage,
    String healthContext,
    String formattedDate,
  ) {
    return '''[NGỮ CẢNH SỨC KHỎE — NGÀY $formattedDate]
$healthContext

[CÂU HỎI CỦA TÔI]
$originalMessage

---
[KỸ THUẬT — BẮT BUỘC]
Phần trả lời của bạn tiếp nối sau dấu { đã có sẵn: bắt đầu bằng "reply": ... (JSON hợp lệ). Không viết # | bảng | ```.''';
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

      final response = await _callAnthropicAPI(apiKey!);
      return response;
    } catch (e) {
      debugPrint('NutritionAI Error: $e');
      
      // Phân loại lỗi để hiển thị thông báo phù hợp
      String userMessage;
      if (e.toString().contains('TimeoutException') || 
          e.toString().contains('Timeout')) {
        userMessage = 'Kết nối đến máy chủ AI đang chậm. Vui lòng thử lại sau vài giây.';
      } else if (e.toString().contains('Connection closed') ||
                 e.toString().contains('SocketException') ||
                 e.toString().contains('HandshakeException')) {
        userMessage = 'Mất kết nối mạng. Vui lòng kiểm tra WiFi/4G và thử lại.';
      } else if (e.toString().contains('ClientException')) {
        userMessage = 'Lỗi kết nối server. Vui lòng thử lại sau.';
      } else {
        userMessage = 'Dịch vụ AI đang bận. Vui lòng thử lại sau.';
      }
      
      return NutritionAIResponse(
        reply: '$userMessage\n\nNếu vấn đề tiếp tục, hãy thử khởi động lại ứng dụng.',
        action: NutritionIntent.chat,
      );
    }
  }

  /// Gọi Anthropic API
  Future<NutritionAIResponse> _callAnthropicAPI(String apiKey) async {
    final url = Uri.parse(_anthropicBaseUrl);

    // System prompt + date context
    final now = DateTime.now();
    final formattedDate =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
    final healthContext = await _fetchHealthContext();

    // ─── Build conversation messages ───────────────────────────────────────
    // KEY FIX: Inject health context + JSON reminder into the LAST user message
    // (= current request), NOT the first historical message.
    // When history is long and old messages are trimmed, the first message
    // disappears and the model loses the JSON format instruction, causing it
    // to return plain Vietnamese text instead of JSON → no data is saved.
    final contents = <Map<String, dynamic>>[];

    // Find the index of the LAST user message in history
    int lastUserIdx = -1;
    for (int i = _conversationHistory.length - 1; i >= 0; i--) {
      if (_conversationHistory[i].role == 'user') {
        lastUserIdx = i;
        break;
      }
    }

    String lastRole = '';
    for (int i = 0; i < _conversationHistory.length; i++) {
      final msg = _conversationHistory[i];
      if (contents.isEmpty && msg.role != 'user') {
        continue; // Anthropic API requires messages to start with 'user'
      }

      String msgContent = msg.content;

      // Inject health context + JSON reminder ONLY into the CURRENT (last) user message
      if (msg.role == 'user' && i == lastUserIdx) {
        msgContent = _buildContextualUserMessage(
          msg.content,
          healthContext,
          formattedDate,
        );
      }

      if (contents.isNotEmpty && msg.role == lastRole) {
        contents.last['content'] = '${contents.last['content']}\n\n$msgContent';
      } else {
        contents.add({'role': msg.role, 'content': msgContent});
        lastRole = msg.role;
      }
    }

    final dynamicPrompt = _systemPrompt
        .replaceAll('{{CURRENT_DATE}}', formattedDate)
        .replaceAll('{{USER_HEALTH_DATA}}', healthContext);

    // Guard: empty contents → inject placeholder so Anthropic doesn't reject
    final messagesToSend =
        contents.isEmpty
            ? [
              {
                'role': 'user',
                'content':
                    '(Ngữ cảnh trống — hãy chờ tin nhắn tiếp theo của người dùng)',
              },
            ]
            : contents;

    final requestBody = {
      'model': 'claude-haiku-4-5-20251001',
      'system': dynamicPrompt,
      // Prefill `{` buộc model tiếp tục bằng "reply":... — tránh trả markdown (# | bảng)
      'messages': [
        ...messagesToSend,
        {'role': 'assistant', 'content': '{'},
      ],
      'max_tokens': 2048,
      'temperature': 0,
    };

    final httpResponse = await http
        .post(
          url,
          headers: {
            'x-api-key': apiKey,
            'Authorization': 'Bearer $apiKey',
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(_httpTimeout);

    if (httpResponse.statusCode != 200) {
      throw Exception(
        'Anthropic API error: ${httpResponse.statusCode} - ${httpResponse.body}',
      );
    }

    final responseJson = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    String text = '';

    if (responseJson['content'] != null && responseJson['content'] is List) {
      for (var block in responseJson['content']) {
        if (block['type'] == 'text') {
          text = block['text'] ?? '';
          break;
        }
      }
    }

    if (text.isEmpty) {
      throw Exception('No valid text response from Anthropic API');
    }

    // Ghép với prefill `{`: proxy đôi khi trả cả `{` prefill + `{` từ model → {{ "reply"
    final combined = _normalizePrefillJsonResponse(text);
    debugPrint('[AI-RAW] first100=${combined.length > 100 ? combined.substring(0, 100) : combined}');
    final parsed = _parseAIResponse(combined);
    debugPrint('[AI-PARSED] action=${parsed.action} hasLogData=${parsed.logData != null} hasWater=${parsed.waterAmount != null} hasSleep=${parsed.sleepLogData != null}');

    // Save the human-readable reply (not the raw JSON) into conversation history
    // so the model doesn't get confused by JSON on the next turn.
    _conversationHistory.add(
      ConversationMessage(role: 'assistant', content: parsed.reply),
    );

    return parsed;
  }

  /// Chuẩn hóa phản hồi khi dùng assistant prefill `{`:
  /// - Model/proxy có thể trả `{{"reply":...` hoặc `{{{...` — jsonDecode lỗi tại ký tự 2.
  /// - Gộp mọi `{` lặp lại ở đầu thành một `{` duy nhất; nếu thiếu `{` thì thêm.
  String _normalizePrefillJsonResponse(String apiText) {
    var s = apiText.trim();
    if (s.startsWith('\uFEFF')) {
      s = s.substring(1);
    }
    final leadingBraces = RegExp(r'^\{+');
    final m = leadingBraces.firstMatch(s);
    if (m != null) {
      final n = m.group(0)!.length;
      if (n > 1) {
        s = '{${s.substring(m.end)}';
      }
    } else {
      s = '{$s';
    }
    return s;
  }

  /// Parse JSON response từ AI
  /// Escapes literal control characters (\n, \r, \t) that appear INSIDE
  /// JSON string values — replacing them with their JSON-escaped equivalents.
  /// This fixes FormatException when the AI returns a multi-line reply field
  /// using real newlines instead of \\n sequences.
  String _sanitizeJsonString(String raw) {
    final buf = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];

      if (escaped) {
        escaped = false;
        buf.write(ch);
        continue;
      }

      if (ch == '\\' && inString) {
        escaped = true;
        buf.write(ch);
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        buf.write(ch);
        continue;
      }

      // While inside a JSON string, replace bare control characters
      if (inString) {
        if (ch == '\n') {
          buf.write(r'\n');
          continue;
        }
        if (ch == '\r') {
          buf.write(r'\r');
          continue;
        }
        if (ch == '\t') {
          buf.write(r'\t');
          continue;
        }
      }

      buf.write(ch);
    }
    return buf.toString();
  }

  NutritionAIResponse _parseAIResponse(String text) {
    try {
      // Clean up the text (remove ALL variations of markdown code blocks)
      String cleanText = text.trim();

      // Remove ```json\n...\n``` or ```\n...\n``` patterns
      cleanText = cleanText.replaceAll(RegExp(r'```json\s*\n?'), '');
      cleanText = cleanText.replaceAll(RegExp(r'```\s*\n?'), '');
      cleanText = cleanText.replaceAll(RegExp(r'\n```'), '');
      cleanText = cleanText.trim();

      // If text doesn't start with '{', search for embedded JSON object
      if (!cleanText.startsWith('{')) {
        final jsonStart = cleanText.indexOf('{');
        if (jsonStart != -1) {
          cleanText = cleanText.substring(jsonStart);
        }
      }

      // Fix {{... do proxy/prefill + model đều trả dấu {
      cleanText = _normalizePrefillJsonResponse(cleanText);

      // Sanitize literal control characters inside JSON string values
      // (e.g. real \n instead of \\n in the "reply" field)
      cleanText = _sanitizeJsonString(cleanText);

      // Try direct parse first
      try {
        final json = jsonDecode(cleanText) as Map<String, dynamic>;
        if (json.containsKey('reply')) {
          return _buildResponseFromJson(json);
        }
      } catch (_) {}

      // Try to find and extract the JSON object
      final json = _tryDecodeEmbeddedNutritionJson(cleanText);
      if (json != null) {
        return _buildResponseFromJson(json);
      }

      // Fallback: extract what we can and return as chat
      debugPrint(
        'Primary JSON parse failed: no valid schema object in response',
      );
      String cleanReply = cleanText;
      cleanReply = cleanReply.replaceAll(
        RegExp(r'```.*?```', dotAll: true),
        '',
      );
      cleanReply = cleanReply.replaceAll(RegExp(r'\s+'), ' ').trim();
      return NutritionAIResponse(
        reply:
            cleanReply.isNotEmpty && cleanReply.length > 10
                ? cleanReply.substring(
                  0,
                  cleanReply.length > 300 ? 300 : cleanReply.length,
                )
                : 'Xin lỗi, tôi không thể trả lời lúc này.',
        action: NutritionIntent.chat,
      );
    } catch (e) {
      debugPrint('Parse error: $e, text: $text');
      String safeReply = text.trim();
      if (safeReply.length > 300) {
        safeReply = '${safeReply.substring(0, 300)}...';
      }
      return NutritionAIResponse(
        reply: safeReply,
        action: NutritionIntent.chat,
      );
    }
  }

  NutritionAIResponse _buildResponseFromJson(Map<String, dynamic> json) {
    final reply = json['reply'] as String? ?? 'Xin lỗi, tôi không hiểu.';
    final actionStr = (json['action'] as String?)?.toUpperCase() ?? 'CHAT';
    final logDataJson = _asStringKeyMap(json['log_data']);
    final sleepLogDataJson = _asStringKeyMap(json['sleep_log_data']);
    final waterAmount =
        json['water_amount'] != null ? _parseInt(json['water_amount']) : null;

    NutritionIntent action;
    switch (actionStr) {
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
      case 'SUGGEST':
        action = NutritionIntent.suggest;
        break;
      default:
        action = NutritionIntent.chat;
    }

    LogData? logData;
    SleepLogData? sleepLogData;

    // Model thường trả action=CHAT/INFO nhưng vẫn có log_data — app cần ghi DB.
    // Ưu tiên: LOG (có log_data) > SLEEP (có sleep_log_data) > WATER (có water_amount).
    if (logDataJson != null) {
      try {
        logData = LogData.fromJson(logDataJson);
        action = NutritionIntent.log;
      } catch (e, st) {
        debugPrint('[NutritionAI] LogData.fromJson failed: $e\\n$st');
      }
    } else if (sleepLogDataJson != null) {
      try {
        sleepLogData = SleepLogData.fromJson(sleepLogDataJson);
        action = NutritionIntent.sleep;
      } catch (e, st) {
        debugPrint('[NutritionAI] SleepLogData.fromJson failed: $e\\n$st');
      }
    } else if (waterAmount != null && waterAmount > 0) {
      action = NutritionIntent.water;
    }

    List<MealSuggestion>? suggestions;
    if (action == NutritionIntent.suggest && json['suggestions'] != null) {
      suggestions =
          (json['suggestions'] as List).map((s) {
            return MealSuggestion(
              name: s['name'] ?? '',
              nameEn: s['name_en'] ?? s['name'] ?? '',
              description: s['description'] ?? '',
              calories: _parseDouble(s['calories']),
              protein: _parseDouble(s['protein'] ?? s['protein_g']),
              carbs: _parseDouble(s['carbs'] ?? s['carbs_g']),
              fat: _parseDouble(s['fat'] ?? s['fat_g']),
              reason: s['reason'] ?? '',
            );
          }).toList();
    }

    return NutritionAIResponse(
      reply: reply,
      action: action,
      logData: logData,
      sleepLogData: sleepLogData,
      waterAmount: waterAmount,
      suggestions: suggestions,
    );
  }

  /// Trích một object `{ ... }` cân bằng tại [start] (bỏ qua `{`/`}` trong chuỗi JSON).
  String? _extractBalancedJsonObject(String input, int start) {
    if (start < 0 || start >= input.length || input[start] != '{') {
      return null;
    }
    int depth = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = start; i < input.length; i++) {
      final ch = input[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (ch == '\\' && inString) {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (ch == '{') {
          depth++;
        } else if (ch == '}') {
          depth--;
          if (depth == 0) {
            return input.substring(start, i + 1);
          }
        }
      }
    }
    return null;
  }

  /// Giải mã JSON phản hồi: thử cả chuỗi, phục hồi cắt cụt, rồi tìm object có `"reply"`.
  Map<String, dynamic>? _tryDecodeEmbeddedNutritionJson(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;

    Map<String, dynamic>? tryDecode(
      String candidate, {
      bool logFailures = false,
    }) {
      try {
        final m = jsonDecode(candidate);
        if (m is Map<String, dynamic> && m.containsKey('reply')) {
          return m;
        }
      } catch (e) {
        if (logFailures) {
          debugPrint('Primary JSON parse failed: $e');
        }
      }
      final recovered = _tryRecoverJson(candidate);
      if (recovered != null && recovered.containsKey('reply')) {
        return recovered;
      }
      return null;
    }

    Map<String, dynamic>? fromSlice(String? slice, {bool logFailures = false}) {
      if (slice == null || slice.isEmpty) return null;
      return tryDecode(slice, logFailures: logFailures);
    }

    final direct = fromSlice(t, logFailures: true);
    if (direct != null) return direct;

    final replyHeader = RegExp(r'\{\s*"reply"\s*:', multiLine: true);
    for (final m in replyHeader.allMatches(t)) {
      final slice = _extractBalancedJsonObject(t, m.start);
      final parsed = fromSlice(slice);
      if (parsed != null) return parsed;
    }

    final actionHeader = RegExp(r'\{\s*"action"\s*:', multiLine: true);
    for (final m in actionHeader.allMatches(t)) {
      final slice = _extractBalancedJsonObject(t, m.start);
      final parsed = fromSlice(slice);
      if (parsed != null && parsed.containsKey('reply')) return parsed;
    }

    return null;
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
      if (ch == '\\' && inString) {
        escaped = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (ch == '{') {
          depth++;
        } else if (ch == '}') {
          depth--;
        }
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
}

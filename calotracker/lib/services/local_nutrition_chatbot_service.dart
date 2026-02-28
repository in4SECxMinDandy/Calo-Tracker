// ============================================================
// LocalNutritionChatbotService
// Rule-based NLP Chatbot hoạt động hoàn toàn OFFLINE
// Không sử dụng bất kỳ API bên ngoài nào
//
// Kiến trúc 3 bước:
//   1. Entity Extraction  — Tìm món ăn + số lượng
//   2. Intent Recognition — LOG (ghi nhật ký) vs INFO (hỏi thông tin)
//   3. Action Execution   — Tính kcal, trả lời, ghi DB
// ============================================================

import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../models/meal.dart';

// ─────────────────────────────────────────────────────────────
// ENUM: Loại ý định của người dùng
// ─────────────────────────────────────────────────────────────
enum ChatbotIntent {
  /// Người dùng hỏi thông tin calo (VD: "1 quả trứng bao nhiêu calo?")
  info,

  /// Người dùng khai báo đã ăn/uống (VD: "tôi vừa ăn 2 quả trứng")
  log,

  /// Không nhận diện được món ăn hoặc câu hỏi
  unknown,
}

// ─────────────────────────────────────────────────────────────
// MODEL: Kết quả trả về từ chatbot
// ─────────────────────────────────────────────────────────────
class ChatbotResponse {
  /// Câu trả lời hiển thị trên UI
  final String reply;

  /// Loại ý định đã nhận diện
  final ChatbotIntent intent;

  /// Tên món ăn đã nhận diện (null nếu intent = UNKNOWN)
  final String? foodName;

  /// Số lượng (null nếu intent = UNKNOWN)
  final int? quantity;

  /// Tổng lượng calo (null nếu intent = UNKNOWN)
  final int? totalKcal;

  const ChatbotResponse({
    required this.reply,
    required this.intent,
    this.foodName,
    this.quantity,
    this.totalKcal,
  });

  @override
  String toString() =>
      'ChatbotResponse(intent: $intent, food: $foodName, qty: $quantity, kcal: $totalKcal)';
}

// ─────────────────────────────────────────────────────────────
// SERVICE: LocalNutritionChatbotService
// ─────────────────────────────────────────────────────────────
class LocalNutritionChatbotService {
  // Singleton pattern
  static LocalNutritionChatbotService? _instance;

  factory LocalNutritionChatbotService() {
    _instance ??= LocalNutritionChatbotService._();
    return _instance!;
  }

  LocalNutritionChatbotService._();

  // ──────────────────────────────────────────────────────────
  // CSDL CỤC BỘ: Tên món ăn -> Kcal trên 1 đơn vị chuẩn
  // Đơn vị chuẩn: 1 quả/bát/ly/cái/phần tùy món
  // ──────────────────────────────────────────────────────────
  static const Map<String, int> _foodDictionary = {
    // Trứng & Sữa
    'trứng gà': 78,       // 1 quả (~50g)
    'trứng vịt': 88,      // 1 quả (~65g)
    'sữa tươi': 150,      // 1 ly (240ml)
    'sữa chua': 100,      // 1 hộp (100g)
    'phô mai': 113,       // 1 miếng (~30g)

    // Cơm & Bún & Mì
    'cơm trắng': 130,     // 1 bát (~150g)
    'cơm tấm': 350,       // 1 phần
    'bún bò': 400,        // 1 tô
    'bún riêu': 380,      // 1 tô
    'phở bò': 450,        // 1 tô
    'phở gà': 400,        // 1 tô
    'mì tôm': 350,        // 1 gói
    'mì quảng': 420,      // 1 tô
    'hủ tiếu': 380,       // 1 tô
    'bánh canh': 360,     // 1 tô

    // Bánh mì & Bánh
    'bánh mì': 270,       // 1 ổ (~100g)
    'bánh mì thịt': 350,  // 1 ổ đầy đủ
    'bánh bao': 200,      // 1 cái (~80g)
    'bánh cuốn': 180,     // 1 phần
    'bánh xèo': 300,      // 1 cái
    'bánh chưng': 250,    // 1 miếng (~100g)

    // Thịt & Cá
    'gà nướng': 250,      // 1 phần (~150g)
    'gà rán': 320,        // 1 miếng (~150g)
    'thịt heo': 200,      // 1 phần (~100g)
    'thịt bò': 220,       // 1 phần (~100g)
    'cá chiên': 180,      // 1 phần (~100g)
    'tôm': 100,           // 1 phần (~100g)
    'mực': 90,            // 1 phần (~100g)

    // Rau củ & Trái cây
    'chuối': 89,          // 1 quả (~100g)
    'táo': 80,            // 1 quả (~150g)
    'cam': 62,            // 1 quả (~130g)
    'xoài': 99,           // 1 quả (~200g)
    'dưa hấu': 46,        // 1 miếng (~200g)
    'rau muống': 20,      // 1 bát (~100g)
    'salad': 50,          // 1 bát (~150g)

    // Đồ uống
    'cafe đen': 5,        // 1 ly (không đường)
    'cafe sữa': 120,      // 1 ly
    'trà sữa': 300,       // 1 ly (500ml)
    'nước cam': 110,      // 1 ly (250ml)
    'sinh tố chuối': 200, // 1 ly (300ml)
    'nước ngọt': 140,     // 1 lon (330ml)
    'bia': 150,           // 1 lon (330ml)

    // Snack & Ăn vặt
    'khoai tây chiên': 365, // 1 phần nhỏ (~100g)
    'bánh quy': 130,        // 5 cái (~30g)
    'kem': 200,             // 1 que
    'chocolate': 150,       // 1 thanh (~30g)
  };

  // ──────────────────────────────────────────────────────────
  // TỪ ĐỒNG NGHĨA: Mapping các cách gọi khác nhau về tên chuẩn
  // Giúp nhận diện "hột gà" -> "trứng gà", "phở" -> "phở bò"...
  // ──────────────────────────────────────────────────────────
  static const Map<String, String> _synonyms = {
    // Trứng
    'hột gà': 'trứng gà',
    'trứng': 'trứng gà',
    'hột vịt': 'trứng vịt',
    'trứng luộc': 'trứng gà',
    'trứng chiên': 'trứng gà',
    'trứng ốp la': 'trứng gà',

    // Cơm
    'cơm': 'cơm trắng',
    'cơm nguội': 'cơm trắng',

    // Phở & Bún
    'phở': 'phở bò',
    'tô phở': 'phở bò',
    'bún': 'bún bò',

    // Cafe
    'cà phê': 'cafe đen',
    'cafe': 'cafe đen',
    'cà phê đen': 'cafe đen',
    'cà phê sữa': 'cafe sữa',
    'cafe sữa đá': 'cafe sữa',
    'bạc xỉu': 'cafe sữa',

    // Trà sữa
    'milk tea': 'trà sữa',
    'trà sữa trân châu': 'trà sữa',

    // Thịt
    'gà': 'gà nướng',
    'thịt gà': 'gà nướng',
    'gà luộc': 'gà nướng',
    'thịt': 'thịt heo',
    'thịt lợn': 'thịt heo',
    'bò': 'thịt bò',
    'thịt bò': 'thịt bò',

    // Bánh mì
    'bánh mì': 'bánh mì',
    'ổ bánh mì': 'bánh mì',

    // Trái cây
    'chuối tiêu': 'chuối',
    'chuối sứ': 'chuối',
    'táo đỏ': 'táo',
    'táo xanh': 'táo',

    // Nước ngọt
    'coca': 'nước ngọt',
    'pepsi': 'nước ngọt',
    'sprite': 'nước ngọt',
    'fanta': 'nước ngọt',

    // Mì tôm
    'mì gói': 'mì tôm',
    'mì ăn liền': 'mì tôm',
    'hảo hảo': 'mì tôm',
  };

  // ──────────────────────────────────────────────────────────
  // TỪ KHÓA HÀNH ĐỘNG: Xác định intent LOG
  // Nếu câu chứa bất kỳ từ nào trong danh sách này -> LOG
  // ──────────────────────────────────────────────────────────
  static const List<String> _logKeywords = [
    // Động từ ăn uống
    'ăn', 'uống', 'húp', 'nhậu', 'nhâm nhi',
    'nhai', 'nuốt', 'thưởng thức',

    // Hành động ghi chép
    'ghi', 'thêm', 'nạp', 'log', 'lưu',
    'ghi lại', 'thêm vào', 'ghi nhật ký',

    // Thì quá khứ / xác nhận đã làm
    'đã ăn', 'vừa ăn', 'mới ăn', 'ăn rồi',
    'đã uống', 'vừa uống', 'uống rồi',
    'sáng nay ăn', 'trưa ăn', 'tối ăn',
    'bữa sáng', 'bữa trưa', 'bữa tối',
    'ăn sáng', 'ăn trưa', 'ăn tối',
    'ăn xong', 'uống xong',

    // Tiếng Anh
    'ate', 'drank', 'had', 'consumed',
  ];

  // ──────────────────────────────────────────────────────────
  // HÀM CHÍNH: Xử lý tin nhắn người dùng
  // ──────────────────────────────────────────────────────────

  /// Xử lý tin nhắn và trả về [ChatbotResponse]
  ///
  /// Quy trình:
  /// 1. Chuẩn hóa chuỗi (lowercase, trim)
  /// 2. Trích xuất số lượng bằng Regex
  /// 3. Tìm món ăn trong từ điển (kể cả từ đồng nghĩa)
  /// 4. Nhận diện intent (LOG vs INFO)
  /// 5. Tính kcal và trả về kết quả
  Future<ChatbotResponse> processMessage(String message) async {
    // ── Bước 0: Chuẩn hóa chuỗi ──────────────────────────
    // Chuyển về chữ thường và loại bỏ khoảng trắng thừa
    final normalized = message.toLowerCase().trim();

    // ── Bước 1a: Trích xuất số lượng bằng Regex ──────────
    // Pattern: tìm số nguyên dương trong câu
    // VD: "2 quả trứng" -> 2, "ăn 3 bát cơm" -> 3
    final quantity = _extractQuantity(normalized);

    // ── Bước 1b: Tìm món ăn trong từ điển ────────────────
    // Ưu tiên: từ đồng nghĩa -> từ điển chính
    final detectedFood = _detectFood(normalized);

    // ── Bước 1c: Xử lý trường hợp không tìm thấy món ────
    if (detectedFood == null) {
      return _buildUnknownResponse(message);
    }

    // ── Bước 2: Nhận diện Intent ──────────────────────────
    // Kiểm tra xem câu có chứa từ khóa hành động không
    final intent = _detectIntent(normalized);

    // ── Bước 3: Tính toán và thực thi ────────────────────
    final kcalPerUnit = _foodDictionary[detectedFood]!;
    final totalKcal = quantity * kcalPerUnit;

    if (intent == ChatbotIntent.log) {
      // Ghi vào database
      await _logToDatabase(detectedFood, quantity, totalKcal);

      return ChatbotResponse(
        reply: '✅ Đã ghi nhận: Hấp thụ **$totalKcal kcal** từ $quantity $detectedFood.',
        intent: ChatbotIntent.log,
        foodName: detectedFood,
        quantity: quantity,
        totalKcal: totalKcal,
      );
    } else {
      // Chỉ trả lời thông tin
      return ChatbotResponse(
        reply: '$quantity $detectedFood chứa khoảng **$totalKcal kcal**.',
        intent: ChatbotIntent.info,
        foodName: detectedFood,
        quantity: quantity,
        totalKcal: totalKcal,
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // PRIVATE METHODS
  // ──────────────────────────────────────────────────────────

  /// Trích xuất số lượng từ câu bằng Regex
  ///
  /// Pattern `\d+` khớp với một hoặc nhiều chữ số liên tiếp.
  /// VD: "ăn 3 bát cơm" -> 3, "2 quả trứng" -> 2
  ///
  /// Edge cases:
  /// - Không có số -> mặc định là 1
  /// - Số âm (VD: "-2") -> bỏ qua, lấy 1 (vì Regex chỉ khớp \d+)
  /// - Số 0 -> lấy 1 (không hợp lệ)
  int _extractQuantity(String normalizedMessage) {
    // Regex: tìm chuỗi chữ số nguyên dương
    final numberRegex = RegExp(r'\d+');
    final match = numberRegex.firstMatch(normalizedMessage);

    if (match == null) return 1; // Mặc định là 1 nếu không có số

    final parsed = int.tryParse(match.group(0)!);
    if (parsed == null || parsed <= 0) return 1; // Bỏ qua số không hợp lệ

    return parsed;
  }

  /// Tìm món ăn trong câu
  ///
  /// Quy trình:
  /// 1. Kiểm tra từ đồng nghĩa trước (để mapping về tên chuẩn)
  /// 2. Kiểm tra từ điển chính
  ///
  /// Trả về tên chuẩn trong [_foodDictionary] hoặc null nếu không tìm thấy
  String? _detectFood(String normalizedMessage) {
    // Bước 1: Kiểm tra từ đồng nghĩa
    // Sắp xếp theo độ dài giảm dần để ưu tiên khớp dài hơn
    // VD: "cafe sữa đá" khớp trước "cafe"
    final sortedSynonyms = _synonyms.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final synonym in sortedSynonyms) {
      if (normalizedMessage.contains(synonym)) {
        final canonicalName = _synonyms[synonym]!;
        // Đảm bảo tên chuẩn tồn tại trong từ điển
        if (_foodDictionary.containsKey(canonicalName)) {
          return canonicalName;
        }
      }
    }

    // Bước 2: Kiểm tra từ điển chính
    // Sắp xếp theo độ dài giảm dần để ưu tiên khớp dài hơn
    // VD: "phở bò" khớp trước "phở"
    final sortedFoods = _foodDictionary.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final food in sortedFoods) {
      if (normalizedMessage.contains(food)) {
        return food;
      }
    }

    return null; // Không tìm thấy
  }

  /// Nhận diện intent từ câu
  ///
  /// Logic: Nếu câu chứa bất kỳ từ khóa hành động nào -> LOG
  /// Ngược lại -> INFO
  ChatbotIntent _detectIntent(String normalizedMessage) {
    // Kiểm tra từng từ khóa hành động
    for (final keyword in _logKeywords) {
      if (normalizedMessage.contains(keyword)) {
        return ChatbotIntent.log;
      }
    }
    return ChatbotIntent.info;
  }

  /// Xây dựng phản hồi khi không nhận diện được món ăn
  ChatbotResponse _buildUnknownResponse(String originalMessage) {
    return const ChatbotResponse(
      reply: '🤔 Xin lỗi, tôi chưa có dữ liệu kcal của món này trong hệ thống.\n\n'
          'Bạn có thể thử:\n'
          '• Nhập tên món khác (VD: "phở bò", "cơm trắng", "trứng gà")\n'
          '• Mô tả cụ thể hơn (VD: "1 bát cơm" thay vì "cơm")',
      intent: ChatbotIntent.unknown,
    );
  }

  // ──────────────────────────────────────────────────────────
  // DATABASE INTEGRATION
  // ──────────────────────────────────────────────────────────

  /// Ghi bữa ăn vào cơ sở dữ liệu cục bộ (SQLite)
  ///
  /// Hiện tại: In log ra console để debug
  /// Tương lai: Kết nối với Supabase hoặc SQLite thực tế
  ///
  /// [foodName] — Tên món ăn đã chuẩn hóa
  /// [quantity] — Số lượng
  /// [totalKcal] — Tổng lượng calo
  Future<void> _logToDatabase(
    String foodName,
    int quantity,
    int totalKcal,
  ) async {
    // Debug log
    debugPrint(
      '>>> [CHATBOT LOG] Ghi nhật ký: $foodName | '
      'Số lượng: $quantity | Kcal: $totalKcal',
    );

    try {
      // Tạo đối tượng Meal để lưu vào SQLite
      final meal = Meal(
        dateTime: DateTime.now(),
        foodName: foodName,
        calories: totalKcal.toDouble(),
        weight: quantity.toDouble(),
        source: 'local_chatbot',
      );

      // Lưu vào SQLite thông qua DatabaseService
      await DatabaseService.insertMeal(meal);

      debugPrint('✅ [CHATBOT LOG] Đã lưu thành công vào database');
    } catch (e) {
      // Không throw exception để không làm crash UI
      debugPrint('❌ [CHATBOT LOG] Lỗi khi lưu: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ──────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả món ăn trong từ điển (để hiển thị gợi ý)
  List<String> get allFoods => _foodDictionary.keys.toList();

  /// Lấy kcal của một món ăn cụ thể (null nếu không có)
  int? getKcalForFood(String foodName) {
    final normalized = foodName.toLowerCase().trim();
    // Kiểm tra từ đồng nghĩa trước
    if (_synonyms.containsKey(normalized)) {
      return _foodDictionary[_synonyms[normalized]];
    }
    return _foodDictionary[normalized];
  }

  /// Tìm kiếm món ăn theo từ khóa (cho tính năng autocomplete)
  List<String> searchFoods(String query) {
    if (query.isEmpty) return [];
    final normalized = query.toLowerCase().trim();
    return _foodDictionary.keys
        .where((food) => food.contains(normalized))
        .toList();
  }
}

// ============================================================
// FoodDatabase - Cơ sở dữ liệu món ăn offline
// 60+ món ăn Việt Nam và quốc tế với đầy đủ thông tin dinh dưỡng
// Không phụ thuộc API bên ngoài — hoạt động hoàn toàn offline
// ============================================================

/// Model đại diện cho một món ăn trong cơ sở dữ liệu
class FoodItem {
  /// Tên món ăn (tiếng Việt)
  final String name;

  /// Các từ khóa tìm kiếm (tên gọi khác, viết tắt, tiếng Anh)
  final List<String> keywords;

  /// Danh mục món ăn
  final FoodCategory category;

  /// Khẩu phần gợi ý (gram)
  final double servingSize;

  /// Đơn vị khẩu phần (ví dụ: "tô", "phần", "cái")
  final String servingUnit;

  /// Calo trên 100g
  final double caloriesPer100g;

  /// Protein trên 100g (gram)
  final double proteinPer100g;

  /// Carbohydrate trên 100g (gram)
  final double carbsPer100g;

  /// Chất béo trên 100g (gram)
  final double fatPer100g;

  /// Chất xơ trên 100g (gram)
  final double fiberPer100g;

  /// Natri trên 100g (mg)
  final double sodiumPer100g;

  /// Thành phần chính
  final List<String> mainIngredients;

  /// Gợi ý thay thế lành mạnh hơn (tên món)
  final List<String> healthierAlternatives;

  /// Ghi chú dinh dưỡng
  final String nutritionNote;

  /// Mức độ lành mạnh (1-5, 5 là lành mạnh nhất)
  final int healthScore;

  const FoodItem({
    required this.name,
    required this.keywords,
    required this.category,
    required this.servingSize,
    required this.servingUnit,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0,
    this.sodiumPer100g = 0,
    required this.mainIngredients,
    this.healthierAlternatives = const [],
    this.nutritionNote = '',
    this.healthScore = 3,
  });

  /// Tính calo cho một khẩu phần cụ thể (gram)
  double caloriesForWeight(double weightGrams) {
    return (caloriesPer100g * weightGrams) / 100;
  }

  /// Tính protein cho một khẩu phần cụ thể (gram)
  double proteinForWeight(double weightGrams) {
    return (proteinPer100g * weightGrams) / 100;
  }

  /// Tính carbs cho một khẩu phần cụ thể (gram)
  double carbsForWeight(double weightGrams) {
    return (carbsPer100g * weightGrams) / 100;
  }

  /// Tính fat cho một khẩu phần cụ thể (gram)
  double fatForWeight(double weightGrams) {
    return (fatPer100g * weightGrams) / 100;
  }

  /// Calo của một khẩu phần gợi ý
  double get servingCalories => caloriesForWeight(servingSize);

  /// Protein của một khẩu phần gợi ý
  double get servingProtein => proteinForWeight(servingSize);

  /// Carbs của một khẩu phần gợi ý
  double get servingCarbs => carbsForWeight(servingSize);

  /// Fat của một khẩu phần gợi ý
  double get servingFat => fatForWeight(servingSize);
}

/// Danh mục món ăn
enum FoodCategory {
  /// Món ăn Việt Nam
  vietnamese,

  /// Món ăn châu Á
  asian,

  /// Món ăn phương Tây
  western,

  /// Đồ uống
  beverage,

  /// Trái cây
  fruit,

  /// Rau củ
  vegetable,

  /// Ngũ cốc & tinh bột
  grain,

  /// Thịt & hải sản
  protein,

  /// Sữa & trứng
  dairy,

  /// Đồ ăn vặt & bánh
  snack,
}

// ─────────────────────────────────────────────────────────────────────────────
/// [FoodDatabaseService] — Service tra cứu thông tin dinh dưỡng offline
///
/// Cung cấp 60+ món ăn phổ biến tại Việt Nam và quốc tế.
/// Hỗ trợ tìm kiếm fuzzy (gần đúng) và gợi ý thay thế lành mạnh.
///
/// Cách dùng:
/// ```dart
/// final result = FoodDatabaseService.search('phở bò');
/// if (result != null) {
///   print('${result.name}: ${result.servingCalories} kcal');
/// }
/// ```
// ─────────────────────────────────────────────────────────────────────────────
class FoodDatabaseService {
  FoodDatabaseService._();

  // ── Cơ sở dữ liệu món ăn ─────────────────────────────────────────────────
  static const List<FoodItem> _database = [
    // ════════════════════════════════════════════════════════════════════════
    // MÓN ĂN VIỆT NAM
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Phở bò',
      keywords: ['pho', 'phở', 'pho bo', 'phở bò', 'noodle soup'],
      category: FoodCategory.vietnamese,
      servingSize: 500,
      servingUnit: 'tô',
      caloriesPer100g: 76,
      proteinPer100g: 5.2,
      carbsPer100g: 10.8,
      fatPer100g: 1.4,
      fiberPer100g: 0.5,
      sodiumPer100g: 280,
      mainIngredients: ['bánh phở', 'thịt bò', 'nước dùng xương', 'hành lá', 'giá đỗ'],
      healthierAlternatives: ['Phở gà', 'Bún bò Huế ít mỡ', 'Cháo gà'],
      nutritionNote: 'Giàu protein từ thịt bò. Nước dùng có thể chứa nhiều natri.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Phở gà',
      keywords: ['pho ga', 'phở gà', 'chicken pho'],
      category: FoodCategory.vietnamese,
      servingSize: 500,
      servingUnit: 'tô',
      caloriesPer100g: 68,
      proteinPer100g: 5.8,
      carbsPer100g: 9.5,
      fatPer100g: 0.9,
      fiberPer100g: 0.5,
      sodiumPer100g: 250,
      mainIngredients: ['bánh phở', 'thịt gà', 'nước dùng gà', 'hành lá'],
      healthierAlternatives: ['Cháo gà', 'Súp gà rau củ'],
      nutritionNote: 'Ít calo hơn phở bò. Protein cao từ thịt gà.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Bún bò Huế',
      keywords: ['bun bo hue', 'bún bò huế', 'bun bo', 'bún bò'],
      category: FoodCategory.vietnamese,
      servingSize: 500,
      servingUnit: 'tô',
      caloriesPer100g: 82,
      proteinPer100g: 5.5,
      carbsPer100g: 11.2,
      fatPer100g: 2.1,
      fiberPer100g: 0.6,
      sodiumPer100g: 320,
      mainIngredients: ['bún', 'thịt bò', 'chả cua', 'sả', 'mắm ruốc'],
      healthierAlternatives: ['Phở gà', 'Bún riêu cua'],
      nutritionNote: 'Cay và đậm đà. Chứa nhiều natri từ mắm ruốc.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Bún chả',
      keywords: ['bun cha', 'bún chả', 'grilled pork noodle'],
      category: FoodCategory.vietnamese,
      servingSize: 400,
      servingUnit: 'phần',
      caloriesPer100g: 145,
      proteinPer100g: 9.8,
      carbsPer100g: 16.5,
      fatPer100g: 4.8,
      fiberPer100g: 1.2,
      sodiumPer100g: 380,
      mainIngredients: ['bún', 'thịt lợn nướng', 'chả viên', 'nước mắm', 'rau sống'],
      healthierAlternatives: ['Bún thịt nướng ít mỡ', 'Bún gà'],
      nutritionNote: 'Cân bằng dinh dưỡng. Ăn kèm nhiều rau sống tốt cho sức khỏe.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Cơm tấm sườn',
      keywords: ['com tam', 'cơm tấm', 'broken rice', 'com tam suon'],
      category: FoodCategory.vietnamese,
      servingSize: 400,
      servingUnit: 'phần',
      caloriesPer100g: 168,
      proteinPer100g: 10.2,
      carbsPer100g: 22.5,
      fatPer100g: 4.5,
      fiberPer100g: 0.8,
      sodiumPer100g: 420,
      mainIngredients: ['cơm tấm', 'sườn nướng', 'bì', 'chả trứng', 'nước mắm'],
      healthierAlternatives: ['Cơm gà luộc', 'Cơm cá hấp', 'Cơm rau củ'],
      nutritionNote: 'Nhiều calo từ sườn nướng. Nên ăn ít bì và chả.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Bánh mì',
      keywords: ['banh mi', 'bánh mì', 'vietnamese sandwich', 'banh mi thit'],
      category: FoodCategory.vietnamese,
      servingSize: 200,
      servingUnit: 'cái',
      caloriesPer100g: 248,
      proteinPer100g: 10.5,
      carbsPer100g: 32.8,
      fatPer100g: 8.2,
      fiberPer100g: 1.5,
      sodiumPer100g: 580,
      mainIngredients: ['bánh mì', 'thịt nguội', 'pate', 'dưa leo', 'rau mùi', 'ớt'],
      healthierAlternatives: ['Bánh mì nguyên cám', 'Bánh mì trứng ít pate'],
      nutritionNote: 'Tiện lợi nhưng nhiều natri. Chọn bánh mì nguyên cám tốt hơn.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Cơm trắng',
      keywords: ['com trang', 'cơm trắng', 'white rice', 'steamed rice', 'com'],
      category: FoodCategory.grain,
      servingSize: 200,
      servingUnit: 'chén',
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.2,
      fatPer100g: 0.3,
      fiberPer100g: 0.4,
      sodiumPer100g: 1,
      mainIngredients: ['gạo trắng'],
      healthierAlternatives: ['Cơm gạo lứt', 'Cơm gạo đen', 'Quinoa'],
      nutritionNote: 'Nguồn carb chính. Gạo lứt có nhiều chất xơ hơn.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Gà luộc',
      keywords: ['ga luoc', 'gà luộc', 'boiled chicken', 'luoc ga'],
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0,
      fatPer100g: 3.6,
      fiberPer100g: 0,
      sodiumPer100g: 74,
      mainIngredients: ['thịt gà', 'muối', 'gừng', 'hành'],
      healthierAlternatives: ['Gà hấp gừng', 'Cá hấp'],
      nutritionNote: 'Protein cao, ít chất béo. Rất tốt cho người tập gym.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Gà nướng',
      keywords: ['ga nuong', 'gà nướng', 'grilled chicken', 'nuong ga'],
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 195,
      proteinPer100g: 29.5,
      carbsPer100g: 0,
      fatPer100g: 8.1,
      fiberPer100g: 0,
      sodiumPer100g: 120,
      mainIngredients: ['thịt gà', 'gia vị nướng', 'sả', 'tỏi'],
      healthierAlternatives: ['Gà luộc', 'Gà hấp'],
      nutritionNote: 'Protein cao. Ít calo hơn gà chiên.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Cá hấp',
      keywords: ['ca hap', 'cá hấp', 'steamed fish', 'hap ca'],
      category: FoodCategory.protein,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 105,
      proteinPer100g: 22.0,
      carbsPer100g: 0,
      fatPer100g: 2.0,
      fiberPer100g: 0,
      sodiumPer100g: 60,
      mainIngredients: ['cá', 'gừng', 'hành lá', 'nước tương'],
      healthierAlternatives: ['Cá hấp chanh sả', 'Tôm hấp'],
      nutritionNote: 'Rất lành mạnh. Giàu omega-3 và protein.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Rau muống xào tỏi',
      keywords: ['rau muong', 'rau muống', 'morning glory', 'xao rau'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'đĩa',
      caloriesPer100g: 45,
      proteinPer100g: 2.6,
      carbsPer100g: 5.4,
      fatPer100g: 1.8,
      fiberPer100g: 2.1,
      sodiumPer100g: 180,
      mainIngredients: ['rau muống', 'tỏi', 'dầu ăn', 'muối'],
      healthierAlternatives: ['Rau muống luộc', 'Cải xanh luộc'],
      nutritionNote: 'Giàu chất xơ và vitamin. Ít calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Canh chua cá',
      keywords: ['canh chua', 'canh chua ca', 'sour soup', 'canh'],
      category: FoodCategory.vietnamese,
      servingSize: 300,
      servingUnit: 'tô',
      caloriesPer100g: 42,
      proteinPer100g: 4.5,
      carbsPer100g: 4.2,
      fatPer100g: 0.8,
      fiberPer100g: 1.2,
      sodiumPer100g: 220,
      mainIngredients: ['cá', 'cà chua', 'dứa', 'giá đỗ', 'me'],
      healthierAlternatives: ['Canh rau củ', 'Súp cá'],
      nutritionNote: 'Ít calo, giàu vitamin C từ cà chua và dứa.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Chè đậu xanh',
      keywords: ['che dau xanh', 'chè đậu xanh', 'mung bean dessert', 'che'],
      category: FoodCategory.vietnamese,
      servingSize: 250,
      servingUnit: 'ly',
      caloriesPer100g: 98,
      proteinPer100g: 3.2,
      carbsPer100g: 19.5,
      fatPer100g: 1.2,
      fiberPer100g: 2.8,
      sodiumPer100g: 15,
      mainIngredients: ['đậu xanh', 'đường', 'nước cốt dừa'],
      healthierAlternatives: ['Chè đậu xanh ít đường', 'Đậu xanh luộc'],
      nutritionNote: 'Giàu chất xơ từ đậu xanh. Nên giảm đường.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Bún riêu cua',
      keywords: ['bun rieu', 'bún riêu', 'crab noodle soup'],
      category: FoodCategory.vietnamese,
      servingSize: 500,
      servingUnit: 'tô',
      caloriesPer100g: 72,
      proteinPer100g: 5.8,
      carbsPer100g: 9.8,
      fatPer100g: 1.5,
      fiberPer100g: 0.8,
      sodiumPer100g: 290,
      mainIngredients: ['bún', 'cua đồng', 'cà chua', 'đậu phụ', 'mắm tôm'],
      healthierAlternatives: ['Phở gà', 'Canh chua cá'],
      nutritionNote: 'Giàu protein từ cua. Mắm tôm chứa nhiều natri.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Gỏi cuốn',
      keywords: ['goi cuon', 'gỏi cuốn', 'fresh spring roll', 'spring roll'],
      category: FoodCategory.vietnamese,
      servingSize: 100,
      servingUnit: 'cuốn',
      caloriesPer100g: 95,
      proteinPer100g: 6.2,
      carbsPer100g: 14.5,
      fatPer100g: 1.2,
      fiberPer100g: 1.8,
      sodiumPer100g: 180,
      mainIngredients: ['bánh tráng', 'tôm', 'thịt lợn', 'bún', 'rau sống'],
      healthierAlternatives: ['Gỏi cuốn chay', 'Salad tôm'],
      nutritionNote: 'Lành mạnh, ít calo. Tốt cho người ăn kiêng.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Cơm gạo lứt',
      keywords: ['com gao lut', 'cơm gạo lứt', 'brown rice', 'gao lut'],
      category: FoodCategory.grain,
      servingSize: 200,
      servingUnit: 'chén',
      caloriesPer100g: 123,
      proteinPer100g: 2.6,
      carbsPer100g: 25.6,
      fatPer100g: 0.9,
      fiberPer100g: 1.8,
      sodiumPer100g: 5,
      mainIngredients: ['gạo lứt'],
      healthierAlternatives: ['Quinoa', 'Yến mạch'],
      nutritionNote: 'Nhiều chất xơ hơn gạo trắng. Tốt cho tiêu hóa và kiểm soát đường huyết.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Đậu phụ chiên',
      keywords: ['dau phu', 'đậu phụ', 'tofu', 'tau hu', 'tàu hũ'],
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 144,
      proteinPer100g: 9.8,
      carbsPer100g: 4.2,
      fatPer100g: 9.5,
      fiberPer100g: 0.3,
      sodiumPer100g: 8,
      mainIngredients: ['đậu phụ', 'dầu ăn'],
      healthierAlternatives: ['Đậu phụ hấp', 'Đậu phụ luộc'],
      nutritionNote: 'Protein thực vật tốt. Chiên làm tăng calo đáng kể.',
      healthScore: 3,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // MÓN ĂN CHÂU Á
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Sushi',
      keywords: ['sushi', 'nigiri', 'maki', 'sashimi'],
      category: FoodCategory.asian,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 145,
      proteinPer100g: 7.5,
      carbsPer100g: 22.5,
      fatPer100g: 2.8,
      fiberPer100g: 0.5,
      sodiumPer100g: 420,
      mainIngredients: ['cơm sushi', 'cá hồi/cá ngừ', 'rong biển', 'wasabi'],
      healthierAlternatives: ['Sashimi', 'Salad rong biển'],
      nutritionNote: 'Cân bằng dinh dưỡng. Sashimi ít calo hơn sushi.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Ramen',
      keywords: ['ramen', 'mì ramen', 'japanese noodle', 'mi ramen'],
      category: FoodCategory.asian,
      servingSize: 500,
      servingUnit: 'tô',
      caloriesPer100g: 88,
      proteinPer100g: 5.2,
      carbsPer100g: 12.8,
      fatPer100g: 2.1,
      fiberPer100g: 0.8,
      sodiumPer100g: 480,
      mainIngredients: ['mì ramen', 'nước dùng', 'thịt lợn', 'trứng', 'rong biển'],
      healthierAlternatives: ['Phở gà', 'Mì soba'],
      nutritionNote: 'Nhiều natri. Chọn ramen ít muối hoặc uống ít nước dùng.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Cơm chiên dương châu',
      keywords: ['com chien', 'cơm chiên', 'fried rice', 'yang chow'],
      category: FoodCategory.asian,
      servingSize: 300,
      servingUnit: 'phần',
      caloriesPer100g: 185,
      proteinPer100g: 6.8,
      carbsPer100g: 28.5,
      fatPer100g: 5.2,
      fiberPer100g: 1.2,
      sodiumPer100g: 380,
      mainIngredients: ['cơm', 'trứng', 'tôm', 'hành lá', 'dầu ăn'],
      healthierAlternatives: ['Cơm trắng + gà luộc', 'Cơm gạo lứt'],
      nutritionNote: 'Nhiều calo từ dầu chiên. Nên ăn ít.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Dim sum',
      keywords: ['dim sum', 'dimsum', 'há cảo', 'ha cao', 'siu mai'],
      category: FoodCategory.asian,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 165,
      proteinPer100g: 8.5,
      carbsPer100g: 20.2,
      fatPer100g: 5.8,
      fiberPer100g: 0.8,
      sodiumPer100g: 420,
      mainIngredients: ['bột mì', 'thịt lợn', 'tôm', 'nấm'],
      healthierAlternatives: ['Há cảo hấp', 'Gỏi cuốn'],
      nutritionNote: 'Hấp tốt hơn chiên. Chứa nhiều natri.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Pad Thai',
      keywords: ['pad thai', 'mi xao thai', 'mì xào thái'],
      category: FoodCategory.asian,
      servingSize: 300,
      servingUnit: 'phần',
      caloriesPer100g: 175,
      proteinPer100g: 8.2,
      carbsPer100g: 24.5,
      fatPer100g: 5.5,
      fiberPer100g: 1.5,
      sodiumPer100g: 520,
      mainIngredients: ['bún gạo', 'tôm/gà', 'trứng', 'đậu phộng', 'giá đỗ'],
      healthierAlternatives: ['Bún xào rau củ', 'Gỏi cuốn'],
      nutritionNote: 'Cân bằng dinh dưỡng. Nhiều natri từ nước mắm.',
      healthScore: 3,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // MÓN ĂN PHƯƠNG TÂY
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Pizza',
      keywords: ['pizza', 'bánh pizza'],
      category: FoodCategory.western,
      servingSize: 200,
      servingUnit: 'miếng (2 miếng)',
      caloriesPer100g: 266,
      proteinPer100g: 11.0,
      carbsPer100g: 33.0,
      fatPer100g: 10.0,
      fiberPer100g: 2.3,
      sodiumPer100g: 598,
      mainIngredients: ['bột mì', 'phô mai', 'sốt cà chua', 'topping'],
      healthierAlternatives: ['Pizza nguyên cám ít phô mai', 'Bánh mì nguyên cám'],
      nutritionNote: 'Nhiều calo và natri. Chọn pizza rau củ ít phô mai.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Burger',
      keywords: ['burger', 'hamburger', 'cheeseburger', 'bánh burger'],
      category: FoodCategory.western,
      servingSize: 250,
      servingUnit: 'cái',
      caloriesPer100g: 295,
      proteinPer100g: 14.5,
      carbsPer100g: 28.5,
      fatPer100g: 13.5,
      fiberPer100g: 1.5,
      sodiumPer100g: 680,
      mainIngredients: ['bánh mì', 'thịt bò', 'phô mai', 'rau xà lách', 'sốt'],
      healthierAlternatives: ['Burger gà nướng', 'Wrap rau củ', 'Salad'],
      nutritionNote: 'Nhiều calo và chất béo bão hòa. Ăn không thường xuyên.',
      healthScore: 1,
    ),

    FoodItem(
      name: 'Pasta',
      keywords: ['pasta', 'spaghetti', 'mì ý', 'mi y', 'fettuccine'],
      category: FoodCategory.western,
      servingSize: 300,
      servingUnit: 'phần',
      caloriesPer100g: 158,
      proteinPer100g: 5.8,
      carbsPer100g: 30.5,
      fatPer100g: 1.8,
      fiberPer100g: 1.8,
      sodiumPer100g: 280,
      mainIngredients: ['mì ý', 'sốt cà chua/kem', 'thịt bò/gà'],
      healthierAlternatives: ['Pasta nguyên cám', 'Zucchini noodles'],
      nutritionNote: 'Pasta nguyên cám có nhiều chất xơ hơn. Sốt kem nhiều calo hơn sốt cà chua.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Salad',
      keywords: ['salad', 'xa lach', 'xà lách', 'green salad', 'caesar salad'],
      category: FoodCategory.western,
      servingSize: 250,
      servingUnit: 'phần',
      caloriesPer100g: 52,
      proteinPer100g: 2.8,
      carbsPer100g: 6.5,
      fatPer100g: 1.5,
      fiberPer100g: 2.5,
      sodiumPer100g: 180,
      mainIngredients: ['rau xà lách', 'cà chua', 'dưa leo', 'sốt salad'],
      healthierAlternatives: ['Salad không sốt', 'Rau luộc'],
      nutritionNote: 'Rất ít calo. Sốt salad có thể thêm nhiều calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Sandwich',
      keywords: ['sandwich', 'banh sandwich', 'bánh sandwich', 'sub'],
      category: FoodCategory.western,
      servingSize: 200,
      servingUnit: 'cái',
      caloriesPer100g: 218,
      proteinPer100g: 10.5,
      carbsPer100g: 28.5,
      fatPer100g: 7.2,
      fiberPer100g: 2.2,
      sodiumPer100g: 520,
      mainIngredients: ['bánh mì', 'thịt nguội/gà', 'phô mai', 'rau'],
      healthierAlternatives: ['Sandwich nguyên cám', 'Wrap rau củ'],
      nutritionNote: 'Chọn bánh nguyên cám và nhân ít chất béo.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Steak',
      keywords: ['steak', 'bít tết', 'bit tet', 'beefsteak'],
      category: FoodCategory.western,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 271,
      proteinPer100g: 26.0,
      carbsPer100g: 0,
      fatPer100g: 18.0,
      fiberPer100g: 0,
      sodiumPer100g: 65,
      mainIngredients: ['thịt bò', 'bơ', 'tỏi', 'thảo mộc'],
      healthierAlternatives: ['Gà nướng', 'Cá hồi nướng'],
      nutritionNote: 'Protein cao nhưng nhiều chất béo bão hòa. Chọn thịt nạc.',
      healthScore: 3,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // ĐỒ UỐNG
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Cà phê sữa đá',
      keywords: ['ca phe sua da', 'cà phê sữa đá', 'iced coffee', 'ca phe'],
      category: FoodCategory.beverage,
      servingSize: 300,
      servingUnit: 'ly',
      caloriesPer100g: 62,
      proteinPer100g: 1.2,
      carbsPer100g: 10.5,
      fatPer100g: 1.8,
      fiberPer100g: 0,
      sodiumPer100g: 25,
      mainIngredients: ['cà phê', 'sữa đặc', 'đá'],
      healthierAlternatives: ['Cà phê đen', 'Trà xanh không đường'],
      nutritionNote: 'Sữa đặc chứa nhiều đường. Nên giảm lượng sữa.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Trà sữa',
      keywords: ['tra sua', 'trà sữa', 'bubble tea', 'milk tea', 'boba'],
      category: FoodCategory.beverage,
      servingSize: 500,
      servingUnit: 'ly',
      caloriesPer100g: 78,
      proteinPer100g: 1.5,
      carbsPer100g: 15.2,
      fatPer100g: 1.8,
      fiberPer100g: 0,
      sodiumPer100g: 30,
      mainIngredients: ['trà', 'sữa', 'đường', 'trân châu'],
      healthierAlternatives: ['Trà xanh không đường', 'Nước ép trái cây'],
      nutritionNote: 'Nhiều đường và calo. Chọn ít đường hoặc không đường.',
      healthScore: 1,
    ),

    FoodItem(
      name: 'Nước ép cam',
      keywords: ['nuoc ep cam', 'nước ép cam', 'orange juice', 'cam ep'],
      category: FoodCategory.beverage,
      servingSize: 250,
      servingUnit: 'ly',
      caloriesPer100g: 45,
      proteinPer100g: 0.7,
      carbsPer100g: 10.4,
      fatPer100g: 0.2,
      fiberPer100g: 0.2,
      sodiumPer100g: 1,
      mainIngredients: ['cam tươi'],
      healthierAlternatives: ['Ăn cam nguyên quả', 'Nước lọc'],
      nutritionNote: 'Giàu vitamin C. Ăn cam nguyên quả tốt hơn vì có chất xơ.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Sinh tố bơ',
      keywords: ['sinh to bo', 'sinh tố bơ', 'avocado smoothie', 'bo xay'],
      category: FoodCategory.beverage,
      servingSize: 300,
      servingUnit: 'ly',
      caloriesPer100g: 95,
      proteinPer100g: 1.2,
      carbsPer100g: 8.5,
      fatPer100g: 6.5,
      fiberPer100g: 2.8,
      sodiumPer100g: 15,
      mainIngredients: ['bơ', 'sữa', 'đường'],
      healthierAlternatives: ['Sinh tố bơ ít đường', 'Bơ ăn trực tiếp'],
      nutritionNote: 'Chất béo lành mạnh từ bơ. Nên giảm đường.',
      healthScore: 3,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // TRÁI CÂY
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Chuối',
      keywords: ['chuoi', 'chuối', 'banana'],
      category: FoodCategory.fruit,
      servingSize: 120,
      servingUnit: 'quả',
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 22.8,
      fatPer100g: 0.3,
      fiberPer100g: 2.6,
      sodiumPer100g: 1,
      mainIngredients: ['chuối'],
      healthierAlternatives: ['Táo', 'Dâu tây'],
      nutritionNote: 'Giàu kali và năng lượng nhanh. Tốt trước khi tập thể dục.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Táo',
      keywords: ['tao', 'táo', 'apple'],
      category: FoodCategory.fruit,
      servingSize: 180,
      servingUnit: 'quả',
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 13.8,
      fatPer100g: 0.2,
      fiberPer100g: 2.4,
      sodiumPer100g: 1,
      mainIngredients: ['táo'],
      healthierAlternatives: [],
      nutritionNote: 'Ít calo, giàu chất xơ. Tốt cho tiêu hóa.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Xoài',
      keywords: ['xoai', 'xoài', 'mango'],
      category: FoodCategory.fruit,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 60,
      proteinPer100g: 0.8,
      carbsPer100g: 15.0,
      fatPer100g: 0.4,
      fiberPer100g: 1.6,
      sodiumPer100g: 1,
      mainIngredients: ['xoài'],
      healthierAlternatives: ['Táo', 'Dưa hấu'],
      nutritionNote: 'Giàu vitamin A và C. Ngọt tự nhiên.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Dưa hấu',
      keywords: ['dua hau', 'dưa hấu', 'watermelon'],
      category: FoodCategory.fruit,
      servingSize: 300,
      servingUnit: 'phần',
      caloriesPer100g: 30,
      proteinPer100g: 0.6,
      carbsPer100g: 7.6,
      fatPer100g: 0.2,
      fiberPer100g: 0.4,
      sodiumPer100g: 1,
      mainIngredients: ['dưa hấu'],
      healthierAlternatives: [],
      nutritionNote: 'Rất ít calo, 92% là nước. Tốt cho hydration.',
      healthScore: 5,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // ĐỒ ĂN VẶT & BÁNH
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Khoai tây chiên',
      keywords: ['khoai tay chien', 'khoai tây chiên', 'french fries', 'fries'],
      category: FoodCategory.snack,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 312,
      proteinPer100g: 3.4,
      carbsPer100g: 41.4,
      fatPer100g: 15.0,
      fiberPer100g: 3.8,
      sodiumPer100g: 210,
      mainIngredients: ['khoai tây', 'dầu chiên', 'muối'],
      healthierAlternatives: ['Khoai tây nướng', 'Khoai lang nướng'],
      nutritionNote: 'Nhiều calo và chất béo. Khoai tây nướng lành mạnh hơn nhiều.',
      healthScore: 1,
    ),

    FoodItem(
      name: 'Bánh quy',
      keywords: ['banh quy', 'bánh quy', 'cookie', 'biscuit'],
      category: FoodCategory.snack,
      servingSize: 50,
      servingUnit: 'phần',
      caloriesPer100g: 480,
      proteinPer100g: 6.5,
      carbsPer100g: 65.0,
      fatPer100g: 22.0,
      fiberPer100g: 2.0,
      sodiumPer100g: 350,
      mainIngredients: ['bột mì', 'đường', 'bơ', 'trứng'],
      healthierAlternatives: ['Hạt hỗn hợp', 'Trái cây tươi'],
      nutritionNote: 'Nhiều đường và chất béo. Ăn ít.',
      healthScore: 1,
    ),

    FoodItem(
      name: 'Yến mạch',
      keywords: ['yen mach', 'yến mạch', 'oatmeal', 'oats', 'oat'],
      category: FoodCategory.grain,
      servingSize: 250,
      servingUnit: 'bát',
      caloriesPer100g: 68,
      proteinPer100g: 2.4,
      carbsPer100g: 12.0,
      fatPer100g: 1.4,
      fiberPer100g: 1.7,
      sodiumPer100g: 49,
      mainIngredients: ['yến mạch', 'nước/sữa'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu chất xơ beta-glucan. Tốt cho tim mạch và kiểm soát đường huyết.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Trứng luộc',
      keywords: ['trung luoc', 'trứng luộc', 'boiled egg', 'hard boiled egg'],
      category: FoodCategory.dairy,
      servingSize: 60,
      servingUnit: 'quả',
      caloriesPer100g: 155,
      proteinPer100g: 13.0,
      carbsPer100g: 1.1,
      fatPer100g: 10.6,
      fiberPer100g: 0,
      sodiumPer100g: 124,
      mainIngredients: ['trứng gà'],
      healthierAlternatives: ['Lòng trắng trứng'],
      nutritionNote: 'Protein hoàn chỉnh. Lòng đỏ chứa nhiều cholesterol nhưng cũng giàu dinh dưỡng.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Sữa chua',
      keywords: ['sua chua', 'sữa chua', 'yogurt', 'yoghurt'],
      category: FoodCategory.dairy,
      servingSize: 150,
      servingUnit: 'hộp',
      caloriesPer100g: 61,
      proteinPer100g: 3.5,
      carbsPer100g: 7.0,
      fatPer100g: 1.5,
      fiberPer100g: 0,
      sodiumPer100g: 46,
      mainIngredients: ['sữa', 'men vi sinh'],
      healthierAlternatives: ['Sữa chua không đường', 'Sữa chua Hy Lạp'],
      nutritionNote: 'Tốt cho hệ tiêu hóa. Chọn loại không đường.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Hạt hỗn hợp',
      keywords: ['hat hon hop', 'hạt hỗn hợp', 'mixed nuts', 'nuts', 'hat dieu', 'hạnh nhân'],
      category: FoodCategory.snack,
      servingSize: 30,
      servingUnit: 'nắm',
      caloriesPer100g: 607,
      proteinPer100g: 20.0,
      carbsPer100g: 21.0,
      fatPer100g: 54.0,
      fiberPer100g: 7.0,
      sodiumPer100g: 5,
      mainIngredients: ['hạnh nhân', 'hạt điều', 'óc chó', 'hạt macadamia'],
      healthierAlternatives: [],
      nutritionNote: 'Chất béo lành mạnh. Ăn ít vì nhiều calo. Tốt cho tim mạch.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Cá hồi nướng',
      keywords: ['ca hoi', 'cá hồi', 'salmon', 'ca hoi nuong'],
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 208,
      proteinPer100g: 20.0,
      carbsPer100g: 0,
      fatPer100g: 13.0,
      fiberPer100g: 0,
      sodiumPer100g: 59,
      mainIngredients: ['cá hồi', 'chanh', 'thảo mộc'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu omega-3 DHA/EPA. Rất tốt cho tim mạch và não bộ.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Tôm hấp',
      keywords: ['tom hap', 'tôm hấp', 'steamed shrimp', 'tom'],
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 99,
      proteinPer100g: 24.0,
      carbsPer100g: 0.2,
      fatPer100g: 0.3,
      fiberPer100g: 0,
      sodiumPer100g: 111,
      mainIngredients: ['tôm', 'muối', 'sả'],
      healthierAlternatives: [],
      nutritionNote: 'Protein rất cao, ít chất béo. Tốt cho người ăn kiêng.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Bơ',
      keywords: ['bo', 'bơ', 'avocado'],
      category: FoodCategory.fruit,
      servingSize: 150,
      servingUnit: 'quả',
      caloriesPer100g: 160,
      proteinPer100g: 2.0,
      carbsPer100g: 8.5,
      fatPer100g: 14.7,
      fiberPer100g: 6.7,
      sodiumPer100g: 7,
      mainIngredients: ['bơ'],
      healthierAlternatives: [],
      nutritionNote: 'Chất béo không bão hòa đơn tốt cho tim. Giàu chất xơ và kali.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Khoai lang',
      keywords: ['khoai lang', 'sweet potato', 'khoai'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'củ',
      caloriesPer100g: 86,
      proteinPer100g: 1.6,
      carbsPer100g: 20.1,
      fatPer100g: 0.1,
      fiberPer100g: 3.0,
      sodiumPer100g: 55,
      mainIngredients: ['khoai lang'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu beta-carotene và chất xơ. Chỉ số đường huyết thấp hơn khoai tây.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Broccoli',
      keywords: ['broccoli', 'bong cai xanh', 'bông cải xanh'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 34,
      proteinPer100g: 2.8,
      carbsPer100g: 6.6,
      fatPer100g: 0.4,
      fiberPer100g: 2.6,
      sodiumPer100g: 33,
      mainIngredients: ['bông cải xanh'],
      healthierAlternatives: [],
      nutritionNote: 'Siêu thực phẩm. Giàu vitamin C, K và chất chống oxy hóa.',
      healthScore: 5,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — THỊT & HẢI SẢN
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Thịt bò nạc',
      keywords: ['thit bo', 'thịt bò', 'beef', 'bo', 'bò'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 250,
      proteinPer100g: 26.0,
      carbsPer100g: 0,
      fatPer100g: 15.0,
      fiberPer100g: 0,
      sodiumPer100g: 72,
      mainIngredients: ['thịt bò'],
      healthierAlternatives: ['Thịt gà ức', 'Cá hồi'],
      nutritionNote: 'Giàu protein và sắt. Chọn phần nạc để giảm chất béo.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Thịt lợn nạc',
      keywords: ['thit lon', 'thịt lợn', 'pork', 'lon', 'lợn', 'heo', 'thit heo'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 242,
      proteinPer100g: 27.0,
      carbsPer100g: 0,
      fatPer100g: 14.0,
      fiberPer100g: 0,
      sodiumPer100g: 62,
      mainIngredients: ['thịt lợn'],
      healthierAlternatives: ['Thịt gà ức', 'Đậu phụ'],
      nutritionNote: 'Protein cao. Chọn phần nạc vai hoặc thăn.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Thịt gà ức',
      keywords: ['uc ga', 'ức gà', 'chicken breast', 'ga uc', 'chicken'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0,
      fatPer100g: 3.6,
      fiberPer100g: 0,
      sodiumPer100g: 74,
      mainIngredients: ['ức gà'],
      healthierAlternatives: [],
      nutritionNote: 'Protein cao nhất trong các loại thịt. Ít chất béo. Lý tưởng cho gym.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Cá ngừ',
      keywords: ['ca ngu', 'cá ngừ', 'tuna', 'ngu'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 144,
      proteinPer100g: 23.0,
      carbsPer100g: 0,
      fatPer100g: 5.0,
      fiberPer100g: 0,
      sodiumPer100g: 47,
      mainIngredients: ['cá ngừ'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu omega-3 và protein. Tốt cho tim mạch.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Cá thu',
      keywords: ['ca thu', 'cá thu', 'mackerel'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 205,
      proteinPer100g: 19.0,
      carbsPer100g: 0,
      fatPer100g: 13.9,
      fiberPer100g: 0,
      sodiumPer100g: 90,
      mainIngredients: ['cá thu'],
      healthierAlternatives: [],
      nutritionNote: 'Rất giàu omega-3. Tốt cho não bộ và tim mạch.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Mực',
      keywords: ['muc', 'mực', 'squid', 'calamari'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 92,
      proteinPer100g: 15.6,
      carbsPer100g: 3.1,
      fatPer100g: 1.4,
      fiberPer100g: 0,
      sodiumPer100g: 44,
      mainIngredients: ['mực'],
      healthierAlternatives: [],
      nutritionNote: 'Ít calo, protein cao. Tốt cho người ăn kiêng.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Cua',
      keywords: ['cua', 'crab'],
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      caloriesPer100g: 97,
      proteinPer100g: 19.0,
      carbsPer100g: 0,
      fatPer100g: 1.8,
      fiberPer100g: 0,
      sodiumPer100g: 293,
      mainIngredients: ['cua'],
      healthierAlternatives: [],
      nutritionNote: 'Protein cao, ít chất béo. Chứa nhiều kẽm và selenium.',
      healthScore: 4,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — RAU CỦ
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Cà chua',
      keywords: ['ca chua', 'cà chua', 'tomato'],
      category: FoodCategory.vegetable,
      servingSize: 150,
      servingUnit: 'quả',
      caloriesPer100g: 18,
      proteinPer100g: 0.9,
      carbsPer100g: 3.9,
      fatPer100g: 0.2,
      fiberPer100g: 1.2,
      sodiumPer100g: 5,
      mainIngredients: ['cà chua'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu lycopene chống oxy hóa. Rất ít calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Dưa leo',
      keywords: ['dua leo', 'dưa leo', 'cucumber', 'dua chuot', 'dưa chuột'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'quả',
      caloriesPer100g: 15,
      proteinPer100g: 0.7,
      carbsPer100g: 3.6,
      fatPer100g: 0.1,
      fiberPer100g: 0.5,
      sodiumPer100g: 2,
      mainIngredients: ['dưa leo'],
      healthierAlternatives: [],
      nutritionNote: '96% là nước. Rất ít calo, tốt cho hydration.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Cà rốt',
      keywords: ['ca rot', 'cà rốt', 'carrot'],
      category: FoodCategory.vegetable,
      servingSize: 100,
      servingUnit: 'củ',
      caloriesPer100g: 41,
      proteinPer100g: 0.9,
      carbsPer100g: 9.6,
      fatPer100g: 0.2,
      fiberPer100g: 2.8,
      sodiumPer100g: 69,
      mainIngredients: ['cà rốt'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu beta-carotene (vitamin A). Tốt cho mắt.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Bắp cải',
      keywords: ['bap cai', 'bắp cải', 'cabbage', 'cai bap'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 25,
      proteinPer100g: 1.3,
      carbsPer100g: 5.8,
      fatPer100g: 0.1,
      fiberPer100g: 2.5,
      sodiumPer100g: 18,
      mainIngredients: ['bắp cải'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin C và K. Rất ít calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Hành tây',
      keywords: ['hanh tay', 'hành tây', 'onion'],
      category: FoodCategory.vegetable,
      servingSize: 100,
      servingUnit: 'củ',
      caloriesPer100g: 40,
      proteinPer100g: 1.1,
      carbsPer100g: 9.3,
      fatPer100g: 0.1,
      fiberPer100g: 1.7,
      sodiumPer100g: 4,
      mainIngredients: ['hành tây'],
      healthierAlternatives: [],
      nutritionNote: 'Chứa quercetin chống viêm. Tốt cho tim mạch.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Tỏi',
      keywords: ['toi', 'tỏi', 'garlic'],
      category: FoodCategory.vegetable,
      servingSize: 10,
      servingUnit: 'tép',
      caloriesPer100g: 149,
      proteinPer100g: 6.4,
      carbsPer100g: 33.1,
      fatPer100g: 0.5,
      fiberPer100g: 2.1,
      sodiumPer100g: 17,
      mainIngredients: ['tỏi'],
      healthierAlternatives: [],
      nutritionNote: 'Allicin trong tỏi có tác dụng kháng khuẩn và tăng miễn dịch.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Gừng',
      keywords: ['gung', 'gừng', 'ginger'],
      category: FoodCategory.vegetable,
      servingSize: 10,
      servingUnit: 'lát',
      caloriesPer100g: 80,
      proteinPer100g: 1.8,
      carbsPer100g: 17.8,
      fatPer100g: 0.8,
      fiberPer100g: 2.0,
      sodiumPer100g: 13,
      mainIngredients: ['gừng'],
      healthierAlternatives: [],
      nutritionNote: 'Gingerol chống viêm và buồn nôn. Tốt cho tiêu hóa.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Ớt chuông',
      keywords: ['ot chuong', 'ớt chuông', 'bell pepper', 'capsicum'],
      category: FoodCategory.vegetable,
      servingSize: 150,
      servingUnit: 'quả',
      caloriesPer100g: 31,
      proteinPer100g: 1.0,
      carbsPer100g: 6.0,
      fatPer100g: 0.3,
      fiberPer100g: 2.1,
      sodiumPer100g: 4,
      mainIngredients: ['ớt chuông'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin C (nhiều hơn cam). Chứa capsaicin tốt cho trao đổi chất.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Nấm',
      keywords: ['nam', 'nấm', 'mushroom', 'nam huong', 'nấm hương'],
      category: FoodCategory.vegetable,
      servingSize: 100,
      servingUnit: 'phần',
      caloriesPer100g: 22,
      proteinPer100g: 3.1,
      carbsPer100g: 3.3,
      fatPer100g: 0.3,
      fiberPer100g: 1.0,
      sodiumPer100g: 5,
      mainIngredients: ['nấm'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin D và B. Protein thực vật tốt.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Đậu bắp',
      keywords: ['dau bap', 'đậu bắp', 'okra', 'lady finger'],
      category: FoodCategory.vegetable,
      servingSize: 100,
      servingUnit: 'phần',
      caloriesPer100g: 33,
      proteinPer100g: 1.9,
      carbsPer100g: 7.5,
      fatPer100g: 0.2,
      fiberPer100g: 3.2,
      sodiumPer100g: 7,
      mainIngredients: ['đậu bắp'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu chất xơ và folate. Tốt cho tiêu hóa và thai kỳ.',
      healthScore: 5,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — NGŨ CỐC & TINH BỘT
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Bánh mì trắng',
      keywords: ['banh mi trang', 'bánh mì trắng', 'white bread', 'bread'],
      category: FoodCategory.grain,
      servingSize: 60,
      servingUnit: 'lát (2 lát)',
      caloriesPer100g: 265,
      proteinPer100g: 9.0,
      carbsPer100g: 49.0,
      fatPer100g: 3.2,
      fiberPer100g: 2.7,
      sodiumPer100g: 491,
      mainIngredients: ['bột mì', 'men', 'muối'],
      healthierAlternatives: ['Bánh mì nguyên cám', 'Bánh mì yến mạch'],
      nutritionNote: 'Chỉ số đường huyết cao. Chọn bánh mì nguyên cám tốt hơn.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Bánh mì nguyên cám',
      keywords: ['banh mi nguyen cam', 'bánh mì nguyên cám', 'whole wheat bread', 'whole grain'],
      category: FoodCategory.grain,
      servingSize: 60,
      servingUnit: 'lát (2 lát)',
      caloriesPer100g: 247,
      proteinPer100g: 13.0,
      carbsPer100g: 41.0,
      fatPer100g: 4.2,
      fiberPer100g: 6.0,
      sodiumPer100g: 400,
      mainIngredients: ['bột mì nguyên cám', 'men', 'muối'],
      healthierAlternatives: [],
      nutritionNote: 'Nhiều chất xơ hơn bánh mì trắng. Chỉ số đường huyết thấp hơn.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Mì gói',
      keywords: ['mi goi', 'mì gói', 'instant noodle', 'ramen goi', 'mi tom'],
      category: FoodCategory.grain,
      servingSize: 75,
      servingUnit: 'gói',
      caloriesPer100g: 436,
      proteinPer100g: 9.0,
      carbsPer100g: 63.0,
      fatPer100g: 16.0,
      fiberPer100g: 2.0,
      sodiumPer100g: 1760,
      mainIngredients: ['mì', 'gói gia vị', 'dầu cọ'],
      healthierAlternatives: ['Phở gà', 'Bún rau củ'],
      nutritionNote: 'Rất nhiều natri và chất béo trans. Ăn không thường xuyên.',
      healthScore: 1,
    ),

    FoodItem(
      name: 'Quinoa',
      keywords: ['quinoa', 'hat quinoa', 'hạt quinoa'],
      category: FoodCategory.grain,
      servingSize: 185,
      servingUnit: 'chén (nấu chín)',
      caloriesPer100g: 120,
      proteinPer100g: 4.4,
      carbsPer100g: 21.3,
      fatPer100g: 1.9,
      fiberPer100g: 2.8,
      sodiumPer100g: 7,
      mainIngredients: ['quinoa'],
      healthierAlternatives: [],
      nutritionNote: 'Protein hoàn chỉnh (có đủ 9 amino acid thiết yếu). Không chứa gluten.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Khoai tây',
      keywords: ['khoai tay', 'khoai tây', 'potato'],
      category: FoodCategory.vegetable,
      servingSize: 200,
      servingUnit: 'củ',
      caloriesPer100g: 77,
      proteinPer100g: 2.0,
      carbsPer100g: 17.5,
      fatPer100g: 0.1,
      fiberPer100g: 2.2,
      sodiumPer100g: 6,
      mainIngredients: ['khoai tây'],
      healthierAlternatives: ['Khoai lang', 'Khoai tây nướng'],
      nutritionNote: 'Giàu kali và vitamin C. Chỉ số đường huyết cao hơn khoai lang.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Ngô',
      keywords: ['ngo', 'ngô', 'corn', 'bap', 'bắp'],
      category: FoodCategory.grain,
      servingSize: 150,
      servingUnit: 'bắp',
      caloriesPer100g: 86,
      proteinPer100g: 3.2,
      carbsPer100g: 19.0,
      fatPer100g: 1.2,
      fiberPer100g: 2.7,
      sodiumPer100g: 15,
      mainIngredients: ['ngô'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu chất xơ và vitamin B. Nguồn carb tốt.',
      healthScore: 4,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — SỮA & TRỨNG
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Sữa tươi',
      keywords: ['sua tuoi', 'sữa tươi', 'milk', 'sua bo', 'sữa bò'],
      category: FoodCategory.dairy,
      servingSize: 240,
      servingUnit: 'ly',
      caloriesPer100g: 61,
      proteinPer100g: 3.2,
      carbsPer100g: 4.8,
      fatPer100g: 3.3,
      fiberPer100g: 0,
      sodiumPer100g: 43,
      mainIngredients: ['sữa bò'],
      healthierAlternatives: ['Sữa tách béo', 'Sữa hạnh nhân'],
      nutritionNote: 'Giàu canxi và protein. Chọn sữa tách béo để giảm calo.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Phô mai',
      keywords: ['pho mai', 'phô mai', 'cheese', 'cheddar', 'mozzarella'],
      category: FoodCategory.dairy,
      servingSize: 30,
      servingUnit: 'lát',
      caloriesPer100g: 402,
      proteinPer100g: 25.0,
      carbsPer100g: 1.3,
      fatPer100g: 33.0,
      fiberPer100g: 0,
      sodiumPer100g: 621,
      mainIngredients: ['sữa', 'men'],
      healthierAlternatives: ['Phô mai ít béo', 'Sữa chua Hy Lạp'],
      nutritionNote: 'Giàu canxi và protein. Nhiều chất béo bão hòa và natri.',
      healthScore: 2,
    ),

    FoodItem(
      name: 'Lòng trắng trứng',
      keywords: ['long trang trung', 'lòng trắng trứng', 'egg white', 'white egg'],
      category: FoodCategory.dairy,
      servingSize: 33,
      servingUnit: 'quả',
      caloriesPer100g: 52,
      proteinPer100g: 10.9,
      carbsPer100g: 0.7,
      fatPer100g: 0.2,
      fiberPer100g: 0,
      sodiumPer100g: 166,
      mainIngredients: ['lòng trắng trứng'],
      healthierAlternatives: [],
      nutritionNote: 'Protein thuần túy, không có cholesterol. Lý tưởng cho gym.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Sữa chua Hy Lạp',
      keywords: ['sua chua hy lap', 'sữa chua hy lạp', 'greek yogurt', 'greek yoghurt'],
      category: FoodCategory.dairy,
      servingSize: 170,
      servingUnit: 'hộp',
      caloriesPer100g: 59,
      proteinPer100g: 10.0,
      carbsPer100g: 3.6,
      fatPer100g: 0.4,
      fiberPer100g: 0,
      sodiumPer100g: 36,
      mainIngredients: ['sữa', 'men vi sinh'],
      healthierAlternatives: [],
      nutritionNote: 'Protein cao gấp đôi sữa chua thường. Tốt cho cơ bắp và tiêu hóa.',
      healthScore: 5,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — DẦU MỠ & GIA VỊ
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Dầu ô liu',
      keywords: ['dau o liu', 'dầu ô liu', 'olive oil', 'o liu'],
      category: FoodCategory.snack,
      servingSize: 14,
      servingUnit: 'muỗng canh',
      caloriesPer100g: 884,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 100.0,
      fiberPer100g: 0,
      sodiumPer100g: 2,
      mainIngredients: ['dầu ô liu'],
      healthierAlternatives: [],
      nutritionNote: 'Chất béo không bão hòa đơn tốt nhất. Tốt cho tim mạch.',
      healthScore: 4,
    ),

    FoodItem(
      name: 'Mật ong',
      keywords: ['mat ong', 'mật ong', 'honey'],
      category: FoodCategory.snack,
      servingSize: 21,
      servingUnit: 'muỗng canh',
      caloriesPer100g: 304,
      proteinPer100g: 0.3,
      carbsPer100g: 82.4,
      fatPer100g: 0,
      fiberPer100g: 0.2,
      sodiumPer100g: 4,
      mainIngredients: ['mật ong'],
      healthierAlternatives: [],
      nutritionNote: 'Đường tự nhiên với kháng khuẩn. Dùng thay đường trắng.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Đường trắng',
      keywords: ['duong trang', 'đường trắng', 'sugar', 'duong'],
      category: FoodCategory.snack,
      servingSize: 12,
      servingUnit: 'muỗng cà phê',
      caloriesPer100g: 387,
      proteinPer100g: 0,
      carbsPer100g: 100.0,
      fatPer100g: 0,
      fiberPer100g: 0,
      sodiumPer100g: 1,
      mainIngredients: ['đường mía'],
      healthierAlternatives: ['Mật ong', 'Đường dừa', 'Stevia'],
      nutritionNote: 'Calo rỗng, không có dinh dưỡng. Hạn chế tối đa.',
      healthScore: 1,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — ĐẬU & HẠT
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Đậu lăng',
      keywords: ['dau lang', 'đậu lăng', 'lentil', 'lentils'],
      category: FoodCategory.protein,
      servingSize: 200,
      servingUnit: 'chén (nấu chín)',
      caloriesPer100g: 116,
      proteinPer100g: 9.0,
      carbsPer100g: 20.0,
      fatPer100g: 0.4,
      fiberPer100g: 7.9,
      sodiumPer100g: 2,
      mainIngredients: ['đậu lăng'],
      healthierAlternatives: [],
      nutritionNote: 'Protein thực vật cao. Giàu chất xơ và sắt. Tốt cho người ăn chay.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Đậu đen',
      keywords: ['dau den', 'đậu đen', 'black bean', 'black beans'],
      category: FoodCategory.protein,
      servingSize: 172,
      servingUnit: 'chén (nấu chín)',
      caloriesPer100g: 132,
      proteinPer100g: 8.9,
      carbsPer100g: 23.7,
      fatPer100g: 0.5,
      fiberPer100g: 8.7,
      sodiumPer100g: 1,
      mainIngredients: ['đậu đen'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu chất xơ và protein. Tốt cho tim mạch và tiêu hóa.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Hạt chia',
      keywords: ['hat chia', 'hạt chia', 'chia seed', 'chia seeds'],
      category: FoodCategory.snack,
      servingSize: 28,
      servingUnit: 'muỗng canh (2 muỗng)',
      caloriesPer100g: 486,
      proteinPer100g: 16.5,
      carbsPer100g: 42.1,
      fatPer100g: 30.7,
      fiberPer100g: 34.4,
      sodiumPer100g: 16,
      mainIngredients: ['hạt chia'],
      healthierAlternatives: [],
      nutritionNote: 'Siêu thực phẩm. Giàu omega-3, chất xơ và canxi. Dùng ít vì nhiều calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Hạt lanh',
      keywords: ['hat lanh', 'hạt lanh', 'flaxseed', 'flax seed'],
      category: FoodCategory.snack,
      servingSize: 10,
      servingUnit: 'muỗng canh',
      caloriesPer100g: 534,
      proteinPer100g: 18.3,
      carbsPer100g: 28.9,
      fatPer100g: 42.2,
      fiberPer100g: 27.3,
      sodiumPer100g: 30,
      mainIngredients: ['hạt lanh'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu omega-3 ALA và lignans. Tốt cho tim mạch và hormone.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Đậu phộng',
      keywords: ['dau phong', 'đậu phộng', 'peanut', 'lac', 'lạc'],
      category: FoodCategory.snack,
      servingSize: 30,
      servingUnit: 'nắm',
      caloriesPer100g: 567,
      proteinPer100g: 25.8,
      carbsPer100g: 16.1,
      fatPer100g: 49.2,
      fiberPer100g: 8.5,
      sodiumPer100g: 18,
      mainIngredients: ['đậu phộng'],
      healthierAlternatives: ['Hạnh nhân', 'Óc chó'],
      nutritionNote: 'Protein cao. Chất béo không bão hòa tốt. Ăn ít vì nhiều calo.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Hạnh nhân',
      keywords: ['hanh nhan', 'hạnh nhân', 'almond', 'almonds'],
      category: FoodCategory.snack,
      servingSize: 28,
      servingUnit: 'nắm (23 hạt)',
      caloriesPer100g: 579,
      proteinPer100g: 21.2,
      carbsPer100g: 21.6,
      fatPer100g: 49.9,
      fiberPer100g: 12.5,
      sodiumPer100g: 1,
      mainIngredients: ['hạnh nhân'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin E và magie. Chất béo lành mạnh. Tốt cho tim mạch.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Óc chó',
      keywords: ['oc cho', 'óc chó', 'walnut', 'walnuts'],
      category: FoodCategory.snack,
      servingSize: 28,
      servingUnit: 'nắm (7 hạt)',
      caloriesPer100g: 654,
      proteinPer100g: 15.2,
      carbsPer100g: 13.7,
      fatPer100g: 65.2,
      fiberPer100g: 6.7,
      sodiumPer100g: 2,
      mainIngredients: ['óc chó'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu omega-3 ALA nhất trong các loại hạt. Tốt cho não bộ.',
      healthScore: 5,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // THỰC PHẨM ĐƠN LẺ — TRÁI CÂY BỔ SUNG
    // ════════════════════════════════════════════════════════════════════════

    FoodItem(
      name: 'Dâu tây',
      keywords: ['dau tay', 'dâu tây', 'strawberry', 'strawberries'],
      category: FoodCategory.fruit,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 32,
      proteinPer100g: 0.7,
      carbsPer100g: 7.7,
      fatPer100g: 0.3,
      fiberPer100g: 2.0,
      sodiumPer100g: 1,
      mainIngredients: ['dâu tây'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin C và chất chống oxy hóa. Rất ít calo.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Việt quất',
      keywords: ['viet quat', 'việt quất', 'blueberry', 'blueberries'],
      category: FoodCategory.fruit,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 57,
      proteinPer100g: 0.7,
      carbsPer100g: 14.5,
      fatPer100g: 0.3,
      fiberPer100g: 2.4,
      sodiumPer100g: 1,
      mainIngredients: ['việt quất'],
      healthierAlternatives: [],
      nutritionNote: 'Siêu thực phẩm. Anthocyanin chống oxy hóa mạnh. Tốt cho não.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Cam',
      keywords: ['cam', 'orange', 'cam tuoi'],
      category: FoodCategory.fruit,
      servingSize: 180,
      servingUnit: 'quả',
      caloriesPer100g: 47,
      proteinPer100g: 0.9,
      carbsPer100g: 11.8,
      fatPer100g: 0.1,
      fiberPer100g: 2.4,
      sodiumPer100g: 0,
      mainIngredients: ['cam'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu vitamin C. Ăn nguyên quả tốt hơn uống nước ép vì có chất xơ.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Nho',
      keywords: ['nho', 'grape', 'grapes'],
      category: FoodCategory.fruit,
      servingSize: 150,
      servingUnit: 'phần',
      caloriesPer100g: 69,
      proteinPer100g: 0.7,
      carbsPer100g: 18.1,
      fatPer100g: 0.2,
      fiberPer100g: 0.9,
      sodiumPer100g: 2,
      mainIngredients: ['nho'],
      healthierAlternatives: ['Dâu tây', 'Việt quất'],
      nutritionNote: 'Resveratrol trong nho đỏ tốt cho tim. Chứa nhiều đường tự nhiên.',
      healthScore: 3,
    ),

    FoodItem(
      name: 'Ổi',
      keywords: ['oi', 'ổi', 'guava'],
      category: FoodCategory.fruit,
      servingSize: 165,
      servingUnit: 'quả',
      caloriesPer100g: 68,
      proteinPer100g: 2.6,
      carbsPer100g: 14.3,
      fatPer100g: 1.0,
      fiberPer100g: 5.4,
      sodiumPer100g: 2,
      mainIngredients: ['ổi'],
      healthierAlternatives: [],
      nutritionNote: 'Vitamin C cao nhất trong các loại trái cây (228mg/100g). Giàu chất xơ.',
      healthScore: 5,
    ),

    FoodItem(
      name: 'Thanh long',
      keywords: ['thanh long', 'dragon fruit', 'pitaya'],
      category: FoodCategory.fruit,
      servingSize: 200,
      servingUnit: 'phần',
      caloriesPer100g: 60,
      proteinPer100g: 1.2,
      carbsPer100g: 13.0,
      fatPer100g: 0,
      fiberPer100g: 3.0,
      sodiumPer100g: 39,
      mainIngredients: ['thanh long'],
      healthierAlternatives: [],
      nutritionNote: 'Giàu chất xơ và vitamin C. Ít calo.',
      healthScore: 4,
    ),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Tìm kiếm món ăn theo tên hoặc từ khóa
  ///
  /// Trả về danh sách kết quả được sắp xếp theo độ liên quan.
  /// [query] — tên món ăn hoặc từ khóa tìm kiếm
  /// [maxResults] — số kết quả tối đa (mặc định 5)
  static List<FoodSearchResult> search(String query, {int maxResults = 5}) {
    if (query.trim().isEmpty) return [];

    final lowerQuery = _normalize(query);
    final results = <FoodSearchResult>[];

    for (final food in _database) {
      final score = _calculateRelevanceScore(food, lowerQuery);
      if (score > 0) {
        results.add(FoodSearchResult(food: food, relevanceScore: score));
      }
    }

    // Sắp xếp theo độ liên quan giảm dần
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return results.take(maxResults).toList();
  }

  /// Tìm kiếm chính xác một món ăn (kết quả tốt nhất)
  static FoodItem? findBest(String query) {
    final results = search(query, maxResults: 1);
    return results.isEmpty ? null : results.first.food;
  }

  /// Lấy tất cả món ăn theo danh mục
  static List<FoodItem> getByCategory(FoodCategory category) {
    return _database.where((f) => f.category == category).toList();
  }

  /// Lấy danh sách món ăn lành mạnh nhất (healthScore >= 4)
  static List<FoodItem> getHealthyFoods() {
    return _database.where((f) => f.healthScore >= 4).toList()
      ..sort((a, b) => b.healthScore.compareTo(a.healthScore));
  }

  /// Lấy gợi ý thay thế lành mạnh cho một món ăn
  static List<FoodItem> getHealthierAlternatives(FoodItem food) {
    final alternatives = <FoodItem>[];
    for (final altName in food.healthierAlternatives) {
      final found = findBest(altName);
      if (found != null) alternatives.add(found);
    }
    return alternatives;
  }

  /// Phân tích dinh dưỡng cho một lượng cụ thể
  ///
  /// [query] — tên món ăn
  /// [weightGrams] — khối lượng (gram), nếu null dùng khẩu phần gợi ý
  static FoodNutritionAnalysis? analyze(String query, {double? weightGrams}) {
    final food = findBest(query);
    if (food == null) return null;

    final weight = weightGrams ?? food.servingSize;
    return FoodNutritionAnalysis(
      food: food,
      weightGrams: weight,
      calories: food.caloriesForWeight(weight),
      protein: food.proteinForWeight(weight),
      carbs: food.carbsForWeight(weight),
      fat: food.fatForWeight(weight),
      fiber: (food.fiberPer100g * weight) / 100,
    );
  }

  /// Tổng số món ăn trong database
  static int get totalFoods => _database.length;

  /// Lấy tất cả món ăn
  static List<FoodItem> get allFoods => List.unmodifiable(_database);

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Chuẩn hóa chuỗi tìm kiếm (lowercase, bỏ dấu cơ bản)
  static String _normalize(String text) {
    return text.toLowerCase().trim();
  }

  /// Tính điểm liên quan của một món ăn với query
  static double _calculateRelevanceScore(FoodItem food, String query) {
    double score = 0;

    // Khớp chính xác tên
    if (_normalize(food.name) == query) return 100;

    // Tên chứa query
    if (_normalize(food.name).contains(query)) score += 50;

    // Query chứa tên
    if (query.contains(_normalize(food.name))) score += 40;

    // Khớp từ khóa
    for (final keyword in food.keywords) {
      final normalizedKeyword = _normalize(keyword);
      if (normalizedKeyword == query) {
        score += 80;
        break;
      }
      if (normalizedKeyword.contains(query) || query.contains(normalizedKeyword)) {
        score += 30;
      }
    }

    // Khớp từng từ trong query
    final queryWords = query.split(RegExp(r'\s+'));
    for (final word in queryWords) {
      if (word.length < 2) continue;
      if (_normalize(food.name).contains(word)) score += 15;
      for (final keyword in food.keywords) {
        if (_normalize(keyword).contains(word)) {
          score += 10;
          break;
        }
      }
    }

    return score;
  }
}

/// Kết quả tìm kiếm món ăn
class FoodSearchResult {
  final FoodItem food;
  final double relevanceScore;

  const FoodSearchResult({
    required this.food,
    required this.relevanceScore,
  });
}

/// Phân tích dinh dưỡng cho một lượng cụ thể
class FoodNutritionAnalysis {
  final FoodItem food;
  final double weightGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const FoodNutritionAnalysis({
    required this.food,
    required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  /// Tỷ lệ protein (% calo từ protein)
  double get proteinRatio => calories > 0 ? (protein * 4 / calories) * 100 : 0;

  /// Tỷ lệ carbs (% calo từ carbs)
  double get carbsRatio => calories > 0 ? (carbs * 4 / calories) * 100 : 0;

  /// Tỷ lệ fat (% calo từ fat)
  double get fatRatio => calories > 0 ? (fat * 9 / calories) * 100 : 0;
}

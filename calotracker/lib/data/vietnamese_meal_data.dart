// Vietnamese Meal Suggestions by Goal
// Gợi ý món ăn Việt theo mục tiêu sức khỏe

/// Enum cho mục tiêu dinh dưỡng
enum NutritionGoal {
  weightLoss, // Giảm cân
  weightGain, // Tăng cân
  maintain, // Duy trì
  muscleGain, // Tăng cơ
}

/// Model cho gợi ý món ăn
class MealSuggestion {
  final String id;
  final String name;
  final String description;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final NutritionGoal goal;
  final MealType mealType;
  final List<String> ingredients;
  final String recipe;
  final String imageUrl;

  const MealSuggestion({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goal,
    required this.mealType,
    required this.ingredients,
    required this.recipe,
    this.imageUrl = '',
  });
}

enum MealType { breakfast, lunch, dinner, snack }

class VietnameseMealData {
  // ==================== GIẢM CÂN ====================
  static const List<MealSuggestion> weightLossMeals = [
    // Bữa sáng giảm cân
    MealSuggestion(
      id: 'wl_b1',
      name: 'Cháo yến mạch rau củ',
      description: 'Cháo yến mạch với cà rốt, bí đỏ, ít calo nhưng no lâu',
      calories: 250,
      protein: 8,
      carbs: 40,
      fat: 5,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.breakfast,
      ingredients: [
        '50g yến mạch',
        '100g bí đỏ',
        '50g cà rốt',
        'Hành lá',
        'Muối',
      ],
      recipe:
          'Nấu yến mạch với nước, thêm bí đỏ và cà rốt thái nhỏ. Nêm nhẹ, ăn nóng.',
    ),
    MealSuggestion(
      id: 'wl_b2',
      name: 'Bánh cuốn chay',
      description:
          'Bánh cuốn nhân nấm, đậu phụ - ít béo, giàu protein thực vật',
      calories: 200,
      protein: 10,
      carbs: 30,
      fat: 3,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.breakfast,
      ingredients: [
        '3 bánh cuốn',
        '50g nấm',
        '50g đậu phụ',
        'Nước mắm pha loãng',
        'Rau thơm',
      ],
      recipe: 'Bánh cuốn nhân nấm và đậu phụ xào, ăn với nước mắm pha loãng.',
    ),
    MealSuggestion(
      id: 'wl_b3',
      name: 'Phở gà ít béo',
      description: 'Phở gà với thịt ức, bỏ da, nước dùng trong',
      calories: 320,
      protein: 25,
      carbs: 40,
      fat: 5,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.breakfast,
      ingredients: [
        '150g bánh phở',
        '100g ức gà',
        'Giá đỗ',
        'Hành, rau thơm',
        'Nước dùng gà',
      ],
      recipe: 'Phở gà nước trong, dùng thịt ức không da, nhiều rau.',
    ),

    // Bữa trưa giảm cân
    MealSuggestion(
      id: 'wl_l1',
      name: 'Cơm gạo lứt + Cá kho tộ',
      description: 'Cơm gạo lứt ít đường huyết, cá kho ít dầu giàu omega-3',
      calories: 380,
      protein: 28,
      carbs: 45,
      fat: 8,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.lunch,
      ingredients: [
        '100g gạo lứt',
        '150g cá basa',
        'Nước màu',
        'Tiêu, ớt',
        'Hành',
      ],
      recipe: 'Kho cá với ít đường, nước mắm, tiêu. Ăn với cơm gạo lứt.',
    ),
    MealSuggestion(
      id: 'wl_l2',
      name: 'Bún chả Hà Nội (phiên bản healthy)',
      description: 'Bún chả nướng không dầu, nhiều rau sống',
      calories: 350,
      protein: 25,
      carbs: 40,
      fat: 10,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.lunch,
      ingredients: [
        '150g bún',
        '100g thịt nạc vai',
        'Rau sống các loại',
        'Nước mắm pha',
      ],
      recipe: 'Thịt nạc nướng trên vỉ (không dầu), ăn với bún và nhiều rau.',
    ),
    MealSuggestion(
      id: 'wl_l3',
      name: 'Gỏi cuốn tôm thịt',
      description: 'Gỏi cuốn tươi mát, ít calo, giàu protein',
      calories: 280,
      protein: 20,
      carbs: 35,
      fat: 5,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.lunch,
      ingredients: [
        '4 cuốn gỏi',
        '100g tôm',
        '50g thịt heo luộc',
        'Bún, rau sống',
        'Nước chấm',
      ],
      recipe: 'Cuốn tôm, thịt, bún với rau sống trong bánh tráng.',
    ),

    // Bữa tối giảm cân
    MealSuggestion(
      id: 'wl_d1',
      name: 'Canh chua cá lóc',
      description: 'Canh chua thanh mát, ít calo, giàu vitamin',
      calories: 200,
      protein: 22,
      carbs: 15,
      fat: 5,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.dinner,
      ingredients: [
        '150g cá lóc',
        'Cà chua',
        'Dứa',
        'Giá đỗ',
        'Rau om, ngò gai',
      ],
      recipe: 'Nấu canh chua với cà chua, dứa, thêm cá lóc, nêm nhẹ.',
    ),
    MealSuggestion(
      id: 'wl_d2',
      name: 'Salad gà nướng kiểu Việt',
      description: 'Gà nướng sả ớt với rau sống, sốt chanh dây',
      calories: 280,
      protein: 30,
      carbs: 15,
      fat: 10,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.dinner,
      ingredients: [
        '150g ức gà',
        'Rau xà lách các loại',
        'Cà chua bi',
        'Chanh dây',
        'Sả, ớt',
      ],
      recipe: 'Gà ướp sả ớt nướng, thái lát, trộn với rau và sốt chanh dây.',
    ),
    MealSuggestion(
      id: 'wl_d3',
      name: 'Rau muống xào tỏi + Đậu phụ sốt cà',
      description: 'Bữa tối thuần chay nhẹ nhàng',
      calories: 220,
      protein: 15,
      carbs: 20,
      fat: 8,
      goal: NutritionGoal.weightLoss,
      mealType: MealType.dinner,
      ingredients: [
        '200g rau muống',
        '150g đậu phụ',
        'Cà chua',
        'Tỏi',
        'Dầu ăn ít',
      ],
      recipe: 'Xào rau muống với tỏi, đậu phụ sốt cà chua tự nhiên.',
    ),
  ];

  // ==================== TĂNG CÂN ====================
  static const List<MealSuggestion> weightGainMeals = [
    // Bữa sáng tăng cân
    MealSuggestion(
      id: 'wg_b1',
      name: 'Xôi gà + Chả lụa',
      description: 'Xôi đầy đủ dinh dưỡng, năng lượng cao',
      calories: 550,
      protein: 25,
      carbs: 65,
      fat: 20,
      goal: NutritionGoal.weightGain,
      mealType: MealType.breakfast,
      ingredients: [
        '200g xôi',
        '100g gà xé',
        '50g chả lụa',
        'Hành phi',
        'Nước mắm',
      ],
      recipe: 'Xôi nếp với gà xé, chả lụa, rưới mỡ hành.',
    ),
    MealSuggestion(
      id: 'wg_b2',
      name: 'Bánh mì thịt đặc biệt',
      description: 'Bánh mì với đầy đủ thịt, pate, trứng',
      calories: 600,
      protein: 28,
      carbs: 55,
      fat: 28,
      goal: NutritionGoal.weightGain,
      mealType: MealType.breakfast,
      ingredients: [
        '1 ổ bánh mì',
        'Thịt nguội',
        'Chả lụa',
        'Pate',
        'Trứng ốp',
        'Rau',
      ],
      recipe: 'Bánh mì kẹp đầy đủ các loại thịt, pate, trứng chiên.',
    ),
    MealSuggestion(
      id: 'wg_b3',
      name: 'Bún bò Huế',
      description: 'Bún bò cay nồng, giàu protein và năng lượng',
      calories: 580,
      protein: 35,
      carbs: 50,
      fat: 25,
      goal: NutritionGoal.weightGain,
      mealType: MealType.breakfast,
      ingredients: [
        '200g bún',
        '150g thịt bò',
        'Giò heo',
        'Chả cua',
        'Rau sống',
      ],
      recipe: 'Bún bò Huế đầy đủ với thịt bò, giò, chả cua.',
    ),

    // Bữa trưa tăng cân
    MealSuggestion(
      id: 'wg_l1',
      name: 'Cơm tấm sườn bì chả',
      description: 'Cơm tấm đầy đủ dinh dưỡng, năng lượng cao',
      calories: 750,
      protein: 40,
      carbs: 70,
      fat: 30,
      goal: NutritionGoal.weightGain,
      mealType: MealType.lunch,
      ingredients: [
        '200g cơm tấm',
        '1 sườn nướng',
        'Bì',
        'Chả trứng',
        'Đồ chua',
        'Nước mắm',
      ],
      recipe: 'Cơm tấm với sườn nướng, bì, chả, đồ chua.',
    ),
    MealSuggestion(
      id: 'wg_l2',
      name: 'Thịt kho tàu + Cơm trắng',
      description: 'Món kho truyền thống giàu protein và béo',
      calories: 680,
      protein: 35,
      carbs: 60,
      fat: 32,
      goal: NutritionGoal.weightGain,
      mealType: MealType.lunch,
      ingredients: [
        '200g thịt ba chỉ',
        '2 trứng',
        'Nước dừa',
        'Cơm',
        'Rau luộc',
      ],
      recipe: 'Thịt ba chỉ kho với nước dừa, trứng. Ăn với cơm.',
    ),
    MealSuggestion(
      id: 'wg_l3',
      name: 'Cơm gà Hải Nam',
      description: 'Cơm gà thơm ngậy, đậm đà',
      calories: 700,
      protein: 38,
      carbs: 65,
      fat: 28,
      goal: NutritionGoal.weightGain,
      mealType: MealType.lunch,
      ingredients: [
        '200g cơm nấu nước gà',
        '200g đùi gà',
        'Dưa leo',
        'Nước chấm gừng',
      ],
      recipe: 'Cơm nấu bằng nước luộc gà, gà luộc thái miếng.',
    ),

    // Bữa tối tăng cân
    MealSuggestion(
      id: 'wg_d1',
      name: 'Lẩu bò',
      description: 'Lẩu bò với nhiều thịt và rau củ',
      calories: 650,
      protein: 45,
      carbs: 40,
      fat: 35,
      goal: NutritionGoal.weightGain,
      mealType: MealType.dinner,
      ingredients: [
        '250g thịt bò các loại',
        'Rau các loại',
        'Mì hoặc bún',
        'Nước lẩu',
      ],
      recipe: 'Lẩu bò với nhiều thịt, rau, mì.',
    ),
    MealSuggestion(
      id: 'wg_d2',
      name: 'Bò lúc lắc + Khoai tây chiên',
      description: 'Thịt bò áp chảo với khoai tây',
      calories: 720,
      protein: 40,
      carbs: 50,
      fat: 38,
      goal: NutritionGoal.weightGain,
      mealType: MealType.dinner,
      ingredients: [
        '200g thịt bò thăn',
        '150g khoai tây',
        'Tỏi, tiêu',
        'Dầu hào',
      ],
      recipe: 'Bò thái hạt lựu áp chảo với tỏi, tiêu. Ăn với khoai chiên.',
    ),
  ];

  // ==================== DUY TRÌ CÂN NẶNG ====================
  static const List<MealSuggestion> maintainMeals = [
    // Bữa sáng duy trì
    MealSuggestion(
      id: 'mt_b1',
      name: 'Phở bò tái',
      description: 'Phở bò truyền thống cân bằng dinh dưỡng',
      calories: 400,
      protein: 25,
      carbs: 50,
      fat: 10,
      goal: NutritionGoal.maintain,
      mealType: MealType.breakfast,
      ingredients: [
        '200g bánh phở',
        '100g bò tái',
        'Giá, hành, rau thơm',
        'Nước dùng bò',
      ],
      recipe: 'Phở bò tái chín với nước dùng trong.',
    ),
    MealSuggestion(
      id: 'mt_b2',
      name: 'Bún riêu cua',
      description: 'Bún riêu với gạch cua, cà chua',
      calories: 380,
      protein: 22,
      carbs: 48,
      fat: 10,
      goal: NutritionGoal.maintain,
      mealType: MealType.breakfast,
      ingredients: ['200g bún', 'Riêu cua', 'Đậu phụ', 'Cà chua', 'Rau sống'],
      recipe: 'Bún riêu cua với đậu phụ rán, rau sống.',
    ),

    // Bữa trưa duy trì
    MealSuggestion(
      id: 'mt_l1',
      name: 'Cơm văn phòng cân bằng',
      description: 'Cơm với protein, rau và tinh bột hợp lý',
      calories: 500,
      protein: 30,
      carbs: 55,
      fat: 15,
      goal: NutritionGoal.maintain,
      mealType: MealType.lunch,
      ingredients: ['150g cơm', '100g thịt/cá', 'Rau xào', 'Canh rau'],
      recipe: 'Cơm với một món mặn, rau xào, canh rau.',
    ),
    MealSuggestion(
      id: 'mt_l2',
      name: 'Bún thịt nướng',
      description: 'Bún thịt nướng với rau sống, nước mắm',
      calories: 480,
      protein: 28,
      carbs: 52,
      fat: 15,
      goal: NutritionGoal.maintain,
      mealType: MealType.lunch,
      ingredients: [
        '200g bún',
        '100g thịt nướng',
        'Rau sống',
        'Đậu phộng',
        'Nước mắm',
      ],
      recipe: 'Bún với thịt nướng, rau sống, nước mắm pha.',
    ),

    // Bữa tối duy trì
    MealSuggestion(
      id: 'mt_d1',
      name: 'Cá kho + Canh rau',
      description: 'Bữa tối cân bằng với cá và rau',
      calories: 420,
      protein: 28,
      carbs: 40,
      fat: 15,
      goal: NutritionGoal.maintain,
      mealType: MealType.dinner,
      ingredients: ['150g cá', '100g cơm', 'Canh rau', 'Rau luộc'],
      recipe: 'Cá kho, canh rau, rau luộc, cơm vừa.',
    ),
    MealSuggestion(
      id: 'mt_d2',
      name: 'Thịt bò xào rau củ',
      description: 'Thịt bò xào với nhiều rau củ màu sắc',
      calories: 450,
      protein: 32,
      carbs: 35,
      fat: 18,
      goal: NutritionGoal.maintain,
      mealType: MealType.dinner,
      ingredients: [
        '120g thịt bò',
        'Ớt chuông',
        'Hành tây',
        'Cà rốt',
        'Bông cải',
      ],
      recipe: 'Xào bò với rau củ, nêm dầu hào, tiêu.',
    ),
  ];

  // ==================== TĂNG CƠ ====================
  static const List<MealSuggestion> muscleGainMeals = [
    // Bữa sáng tăng cơ
    MealSuggestion(
      id: 'mg_b1',
      name: 'Trứng ốp + Bánh mì + Bơ',
      description: 'Bữa sáng giàu protein và chất béo tốt',
      calories: 500,
      protein: 25,
      carbs: 35,
      fat: 28,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.breakfast,
      ingredients: ['3 trứng', '2 lát bánh mì', '1/2 quả bơ', 'Cà chua'],
      recipe: 'Trứng ốp la, bánh mì nướng, bơ tươi.',
    ),
    MealSuggestion(
      id: 'mg_b2',
      name: 'Sinh tố protein chuối bơ',
      description: 'Smoothie giàu protein sau tập',
      calories: 450,
      protein: 30,
      carbs: 45,
      fat: 15,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.breakfast,
      ingredients: ['1 chuối', '1/2 bơ', '200ml sữa', '30g whey', 'Yến mạch'],
      recipe: 'Xay nhuyễn tất cả nguyên liệu.',
    ),

    // Bữa trưa tăng cơ
    MealSuggestion(
      id: 'mg_l1',
      name: 'Cơm + Ức gà nướng + Rau',
      description: 'Bữa trưa kinh điển cho gymer',
      calories: 550,
      protein: 45,
      carbs: 50,
      fat: 15,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.lunch,
      ingredients: ['150g cơm', '200g ức gà', 'Bông cải', 'Cà rốt'],
      recipe: 'Ức gà nướng, cơm trắng, rau củ luộc.',
    ),
    MealSuggestion(
      id: 'mg_l2',
      name: 'Bánh mì kẹp thịt bò + Trứng',
      description: 'Burger Việt giàu protein',
      calories: 600,
      protein: 40,
      carbs: 45,
      fat: 28,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.lunch,
      ingredients: [
        '1 ổ bánh mì',
        '150g bò xay',
        '2 trứng',
        'Rau sống',
        'Phô mai',
      ],
      recipe: 'Bò xay áp chảo, trứng ốp, kẹp bánh mì với rau.',
    ),

    // Bữa tối tăng cơ
    MealSuggestion(
      id: 'mg_d1',
      name: 'Cá hồi nướng + Khoai lang',
      description: 'Omega-3 và carb phức hợp cho phục hồi cơ',
      calories: 520,
      protein: 35,
      carbs: 45,
      fat: 20,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.dinner,
      ingredients: ['200g cá hồi', '150g khoai lang', 'Rau xanh', 'Chanh, tỏi'],
      recipe: 'Cá hồi nướng chanh tỏi, khoai lang nướng.',
    ),
    MealSuggestion(
      id: 'mg_d2',
      name: 'Bò bít tết + Salad',
      description: 'Thịt bò giàu protein, sắt cho phát triển cơ',
      calories: 580,
      protein: 42,
      carbs: 20,
      fat: 35,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.dinner,
      ingredients: [
        '200g thịt bò thăn',
        'Rau xà lách',
        'Cà chua',
        'Sốt dầu giấm',
      ],
      recipe: 'Bò áp chảo medium, ăn với salad tươi.',
    ),

    // Snack tăng cơ
    MealSuggestion(
      id: 'mg_s1',
      name: 'Sữa chua Hy Lạp + Hạt',
      description: 'Snack protein casein, ăn trước ngủ',
      calories: 280,
      protein: 20,
      carbs: 25,
      fat: 10,
      goal: NutritionGoal.muscleGain,
      mealType: MealType.snack,
      ingredients: ['200g sữa chua Hy Lạp', 'Granola', 'Hạt chia', 'Mật ong'],
      recipe: 'Trộn sữa chua với granola, hạt, mật ong.',
    ),
  ];

  /// Lấy gợi ý theo mục tiêu
  static List<MealSuggestion> getByGoal(NutritionGoal goal) {
    switch (goal) {
      case NutritionGoal.weightLoss:
        return weightLossMeals;
      case NutritionGoal.weightGain:
        return weightGainMeals;
      case NutritionGoal.maintain:
        return maintainMeals;
      case NutritionGoal.muscleGain:
        return muscleGainMeals;
    }
  }

  /// Lấy gợi ý theo loại bữa
  static List<MealSuggestion> getByMealType(NutritionGoal goal, MealType type) {
    return getByGoal(goal).where((m) => m.mealType == type).toList();
  }

  /// Tất cả món
  static List<MealSuggestion> get allMeals => [
    ...weightLossMeals,
    ...weightGainMeals,
    ...maintainMeals,
    ...muscleGainMeals,
  ];
}

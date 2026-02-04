// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'CaloTracker';

  @override
  String get onboardingTitle => 'Chào mừng đến CaloTracker';

  @override
  String get onboardingSubtitle => 'Theo dõi dinh dưỡng và sức khỏe của bạn';

  @override
  String get step1Title => 'Thông tin cá nhân';

  @override
  String get step2Title => 'Mục tiêu của bạn';

  @override
  String get name => 'Tên';

  @override
  String get nameHint => 'Nhập tên của bạn';

  @override
  String get height => 'Chiều cao';

  @override
  String get heightUnit => 'cm';

  @override
  String get heightHint => 'Nhập chiều cao';

  @override
  String get weight => 'Cân nặng';

  @override
  String get weightUnit => 'kg';

  @override
  String get weightHint => 'Nhập cân nặng';

  @override
  String get age => 'Tuổi';

  @override
  String get ageHint => 'Nhập tuổi';

  @override
  String get gender => 'Giới tính';

  @override
  String get male => 'Nam';

  @override
  String get female => 'Nữ';

  @override
  String get next => 'Tiếp theo';

  @override
  String get back => 'Quay lại';

  @override
  String get start => 'Bắt đầu';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get close => 'Đóng';

  @override
  String get done => 'Xong';

  @override
  String get goalLose => 'Giảm cân';

  @override
  String get goalLoseDesc => 'Giảm 20% lượng calo';

  @override
  String get goalMaintain => 'Duy trì';

  @override
  String get goalMaintainDesc => 'Giữ nguyên cân nặng';

  @override
  String get goalGain => 'Tăng cân';

  @override
  String get goalGainDesc => 'Tăng 20% lượng calo';

  @override
  String get homeTitle => 'Hôm nay';

  @override
  String get cameraCard => 'Chụp ảnh';

  @override
  String get cameraCardDesc => 'Quét món ăn';

  @override
  String get chatbotCard => 'Chatbot';

  @override
  String get chatbotCardDesc => 'Hỏi về dinh dưỡng';

  @override
  String get caloriesIntake => 'Nạp vào';

  @override
  String get caloriesBurned => 'Đốt cháy';

  @override
  String get caloriesNet => 'Thực tế';

  @override
  String get kcal => 'kcal';

  @override
  String get targetProgress => 'mục tiêu';

  @override
  String get upcomingGym => 'Lịch tập sắp tới';

  @override
  String get noUpcomingGym => 'Chưa có lịch tập';

  @override
  String get addGymSession => 'Thêm lịch tập';

  @override
  String get viewHistory => 'Xem lịch sử';

  @override
  String get chatbotTitle => 'Chatbot Dinh Dưỡng';

  @override
  String get chatbotHint => 'Nhập món ăn (VD: 200g phở bò)';

  @override
  String get chatbotPlaceholder => 'Hỏi về bất kỳ món ăn nào...';

  @override
  String get addToDiary => 'Thêm vào nhật ký';

  @override
  String get added => 'Đã thêm!';

  @override
  String get scanning => 'Đang quét...';

  @override
  String get scanResult => 'Kết quả';

  @override
  String get scanAgain => 'Quét lại';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Chất béo';

  @override
  String get historyTitle => 'Lịch sử';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get noDataForDate => 'Không có dữ liệu';

  @override
  String get mealsToday => 'Bữa ăn hôm nay';

  @override
  String get gymScheduler => 'Lịch tập gym';

  @override
  String get selectTime => 'Chọn giờ';

  @override
  String get startTime => 'Giờ bắt đầu';

  @override
  String get endTime => 'Giờ kết thúc';

  @override
  String get duration => 'Thời lượng';

  @override
  String durationMinutes(Object count) {
    return '$count phút';
  }

  @override
  String durationHours(Object count) {
    return '$count giờ';
  }

  @override
  String get gymType => 'Loại bài tập';

  @override
  String get estimatedCalories => 'Calo đốt cháy (ước tính)';

  @override
  String get caloriesPerHour => 'kcal/giờ';

  @override
  String get markComplete => 'Hoàn thành';

  @override
  String get completed => 'Đã hoàn thành';

  @override
  String get settings => 'Cài đặt';

  @override
  String get appearance => 'Giao diện';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get darkModeOn => 'Đang bật';

  @override
  String get darkModeOff => 'Đang tắt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get country => 'Quốc gia';

  @override
  String get notifications => 'Thông báo';

  @override
  String get notificationsEnabled => 'Đang bật';

  @override
  String get notificationsDisabled => 'Đang tắt';

  @override
  String get testNotification => 'Kiểm tra thông báo';

  @override
  String get testNotificationDesc => 'Gửi thông báo test ngay';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get bodyInfo => 'Thông tin cơ thể';

  @override
  String get currentGoal => 'Mục tiêu hiện tại';

  @override
  String get stats => 'Thống kê';

  @override
  String get totalMeals => 'Tổng bữa ăn';

  @override
  String get totalWorkouts => 'Tổng buổi tập';

  @override
  String get streakDays => 'Ngày liên tiếp';

  @override
  String get about => 'Về ứng dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get rateApp => 'Đánh giá ứng dụng';

  @override
  String get rateAppDesc => 'Chia sẻ trải nghiệm của bạn';

  @override
  String get shareApp => 'Chia sẻ ứng dụng';

  @override
  String get shareAppDesc => 'Giới thiệu cho bạn bè';

  @override
  String get data => 'Dữ liệu';

  @override
  String get exportData => 'Xuất dữ liệu';

  @override
  String get exportDataDesc => 'Lưu dữ liệu ra file';

  @override
  String get clearAllData => 'Xóa tất cả dữ liệu';

  @override
  String get clearAllDataDesc => 'Xóa vĩnh viễn tất cả dữ liệu';

  @override
  String get clearDataConfirm => 'Xóa tất cả dữ liệu?';

  @override
  String get clearDataWarning =>
      'Hành động này không thể hoàn tác. Tất cả bữa ăn, lịch tập và cài đặt sẽ bị xóa.';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get privacyPolicyDesc => 'Đọc chính sách bảo mật';

  @override
  String get termsOfService => 'Điều khoản sử dụng';

  @override
  String get termsOfServiceDesc => 'Đọc điều khoản sử dụng';

  @override
  String get legal => 'Pháp lý';

  @override
  String get sunday => 'Chủ nhật';

  @override
  String get monday => 'Thứ hai';

  @override
  String get tuesday => 'Thứ ba';

  @override
  String get wednesday => 'Thứ tư';

  @override
  String get thursday => 'Thứ năm';

  @override
  String get friday => 'Thứ sáu';

  @override
  String get saturday => 'Thứ bảy';

  @override
  String get errorNetwork => 'Không có kết nối mạng';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi';

  @override
  String get loading => 'Đang tải...';

  @override
  String get retry => 'Thử lại';

  @override
  String get bmrCalculated => 'BMR của bạn';

  @override
  String get dailyTarget => 'Mục tiêu hàng ngày';

  @override
  String get bmrInfo => 'BMR là lượng calo cơ thể đốt khi nghỉ ngơi';

  @override
  String get welcome => 'Xin chào';

  @override
  String get goodMorning => 'Chào buổi sáng';

  @override
  String get goodAfternoon => 'Chào buổi chiều';

  @override
  String get goodEvening => 'Chào buổi tối';

  @override
  String get workoutCard => 'Tập luyện';

  @override
  String get workoutCardDesc => '12 tuần giảm cân';

  @override
  String get workoutProgram => 'Chương Trình Tập Luyện';

  @override
  String get weekLabel => 'Tuần';

  @override
  String get scheduleThisWeek => 'Lịch tuần này';

  @override
  String get todayLabel => 'Hôm nay';

  @override
  String get exercises => 'Bài tập';

  @override
  String get minutes => 'Phút';

  @override
  String get calories => 'Calo';

  @override
  String get watchVideo => 'Xem video hướng dẫn';

  @override
  String get restDay => 'Ngày nghỉ';

  @override
  String get restDayNote => 'Nghỉ ngơi để cơ thể phục hồi';

  @override
  String get instructions => 'Cách thực hiện';

  @override
  String get videoTutorials => 'Video hướng dẫn';

  @override
  String get tips => 'Mẹo hay';

  @override
  String get progress => 'Tiến độ';

  @override
  String get set => 'Set';

  @override
  String get completedLabel => 'Hoàn thành';

  @override
  String get nextSet => 'Set tiếp theo';

  @override
  String get previousSet => 'Set trước';

  @override
  String get complete => 'Hoàn thành';

  @override
  String get successMessage => 'Xuất sắc! Bạn đã hoàn thành!';

  @override
  String get scanFood => 'Quét món ăn';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get analyzing => 'Đang phân tích...';

  @override
  String get recognitionResult => 'Kết quả nhận diện';

  @override
  String get retake => 'Chụp lại';

  @override
  String get addToDiaryAction => 'Thêm vào nhật ký';

  @override
  String get noFoodDetected => 'Không nhận diện được thức ăn trong ảnh';

  @override
  String get aiConfidence => 'Độ tin cậy AI';

  @override
  String get notificationScheduled => 'Đã đặt thông báo';

  @override
  String get reminderTime => 'Thông báo sẽ gửi lúc';

  @override
  String get sessionScheduled => 'Đã đặt lịch tập';

  @override
  String get gymChest => 'Gym ngực';

  @override
  String get gymBack => 'Gym lưng';

  @override
  String get gymShoulders => 'Gym vai';

  @override
  String get gymLegs => 'Gym chân';

  @override
  String get gymArms => 'Gym tay';

  @override
  String get gymAbs => 'Gym bụng';

  @override
  String get gymFullBody => 'Full Body';

  @override
  String get gymRunning => 'Chạy bộ';

  @override
  String get gymWalking => 'Đi bộ';

  @override
  String get gymSwimming => 'Bơi lội';

  @override
  String get gymCycling => 'Đạp xe';

  @override
  String get gymYoga => 'Yoga';

  @override
  String get gymHiit => 'HIIT';

  @override
  String get gymCardio => 'Cardio';

  @override
  String get gymStretching => 'Giãn cơ';

  @override
  String get gymCustom => 'Tùy chỉnh';

  @override
  String get madeWithLove => 'Made with ❤️ in Vietnam';

  @override
  String get waterIntake => 'Nước uống';

  @override
  String get waterTarget => 'Mục tiêu nước';

  @override
  String waterRemaining(Object amount) {
    return 'Còn ${amount}ml';
  }

  @override
  String get waterGoalReached => 'Đã đạt mục tiêu!';

  @override
  String get waterAddCustom => 'Thêm nước';

  @override
  String get waterAdd => 'Thêm';

  @override
  String get waterTipGoalReached => 'Tuyệt vời! Bạn đã uống đủ nước hôm nay!';

  @override
  String get waterTipMorning =>
      'Hãy uống nước vào buổi sáng để bắt đầu ngày mới!';

  @override
  String get waterTipAfternoon => 'Đừng quên uống nước vào buổi chiều!';

  @override
  String get waterTipEvening => 'Uống thêm nước trước khi đi ngủ!';

  @override
  String get waterTipKeepGoing => 'Tiếp tục uống nước đều đặn!';

  @override
  String get waterDailyTarget => 'Mục tiêu hàng ngày';

  @override
  String get waterHistory => 'Lịch sử uống nước';

  @override
  String get waterStats => 'Thống kê nước';

  @override
  String get waterWeeklyAverage => 'Trung bình tuần';

  @override
  String get waterDaysReachedGoal => 'Ngày đạt mục tiêu';

  @override
  String get weightTracking => 'Cân nặng';

  @override
  String get weightCurrent => 'Cân nặng hiện tại';

  @override
  String get weightGoal => 'Mục tiêu';

  @override
  String get weightUpdate => 'Cập nhật cân nặng';

  @override
  String get weightHistory => 'Lịch sử cân nặng';

  @override
  String get weightChange => 'Thay đổi';

  @override
  String get weightTrend => 'Xu hướng';

  @override
  String get weightTrendUp => 'Tăng';

  @override
  String get weightTrendDown => 'Giảm';

  @override
  String get weightTrendStable => 'Ổn định';

  @override
  String get bmi => 'BMI';

  @override
  String get bmiUnderweight => 'Thiếu cân';

  @override
  String get bmiNormal => 'Bình thường';

  @override
  String get bmiOverweight => 'Thừa cân';

  @override
  String get bmiObese => 'Béo phì';

  @override
  String get tapToUpdateWeight => 'Nhấn để cập nhật cân nặng';

  @override
  String get achievements => 'Thành tựu';

  @override
  String get allAchievements => 'Tất cả thành tựu';

  @override
  String get unlocked => 'Đã mở khóa';

  @override
  String get locked => 'Chưa mở khóa';

  @override
  String get secretAchievement => 'Thành tựu bí mật';

  @override
  String get keepUsingToDiscover => 'Tiếp tục sử dụng app để khám phá';

  @override
  String get newAchievement => 'Thành tựu mới!';

  @override
  String get excellent => 'Tuyệt vời!';

  @override
  String get xpRemaining => 'XP còn lại';

  @override
  String get completion => 'Hoàn thành';

  @override
  String get levelBeginner => 'Người mới';

  @override
  String get levelNovice => 'Tập sự';

  @override
  String get levelIntermediate => 'Trung cấp';

  @override
  String get levelAdvanced => 'Nâng cao';

  @override
  String get levelExpert => 'Chuyên gia';

  @override
  String get levelMaster => 'Bậc thầy';

  @override
  String get levelLegend => 'Huyền thoại';

  @override
  String get achievementStreak3 => '3 ngày liên tiếp';

  @override
  String get achievementStreak7 => '7 ngày liên tiếp';

  @override
  String get achievementStreak14 => '14 ngày liên tiếp';

  @override
  String get achievementStreak30 => '30 ngày liên tiếp';

  @override
  String get achievementStreak100 => '100 ngày liên tiếp';

  @override
  String get achievementCalorieFirst => 'Bữa ăn đầu tiên';

  @override
  String get achievementCalorie10 => '10 bữa ăn';

  @override
  String get achievementCalorie50 => '50 bữa ăn';

  @override
  String get achievementCalorie100 => '100 bữa ăn';

  @override
  String get achievementWaterFirst => 'Uống nước đầu tiên';

  @override
  String get achievementWater7 => '7 ngày uống đủ nước';

  @override
  String get achievementWater30 => '30 ngày uống đủ nước';

  @override
  String get achievementWorkoutFirst => 'Buổi tập đầu tiên';

  @override
  String get achievementWorkout10 => '10 buổi tập';

  @override
  String get achievementWorkout50 => '50 buổi tập';

  @override
  String get achievementWeightFirst => 'Cân đầu tiên';

  @override
  String get achievementWeightGoal => 'Đạt mục tiêu cân nặng';

  @override
  String get achievementEarlyBird => 'Chim sớm';

  @override
  String get achievementNightOwl => 'Cú đêm';

  @override
  String get barcodeScanner => 'Quét mã vạch';

  @override
  String get barcodeScan => 'Quét mã vạch';

  @override
  String get barcodeProduct => 'Sản phẩm';

  @override
  String get barcodePlaceInFrame => 'Đặt mã vạch vào khung hình';

  @override
  String get barcodeSearching => 'Đang tìm sản phẩm...';

  @override
  String get barcodeNotFound => 'Không tìm thấy sản phẩm';

  @override
  String get barcodeNutritionPer100g => 'Thông tin dinh dưỡng (100g)';

  @override
  String get barcodeScanAgain => 'Quét lại';

  @override
  String get barcodeWeight => 'Khối lượng';

  @override
  String get barcodeCaloriesFor => 'Calories cho';

  @override
  String get mealSuggestions => 'Gợi ý món ăn';

  @override
  String get suggestionBreakfast => 'Gợi ý bữa sáng';

  @override
  String get suggestionLunch => 'Gợi ý bữa trưa';

  @override
  String get suggestionDinner => 'Gợi ý bữa tối';

  @override
  String get suggestionSnack => 'Gợi ý bữa phụ';

  @override
  String remainingCalories(Object amount) {
    return 'Còn $amount kcal';
  }

  @override
  String get suggestionReason => 'Lý do phù hợp';

  @override
  String get moreSuggestions => 'Xem thêm gợi ý';

  @override
  String get loadingSuggestions => 'Đang tải gợi ý...';

  @override
  String get addToLog => 'Thêm';
}

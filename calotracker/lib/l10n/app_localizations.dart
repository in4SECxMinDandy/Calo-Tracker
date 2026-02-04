import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'CaloTracker'**
  String get appTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến CaloTracker'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi dinh dưỡng và sức khỏe của bạn'**
  String get onboardingSubtitle;

  /// No description provided for @step1Title.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu của bạn'**
  String get step2Title;

  /// No description provided for @name.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get name;

  /// No description provided for @nameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên của bạn'**
  String get nameHint;

  /// No description provided for @height.
  ///
  /// In vi, this message translates to:
  /// **'Chiều cao'**
  String get height;

  /// No description provided for @heightUnit.
  ///
  /// In vi, this message translates to:
  /// **'cm'**
  String get heightUnit;

  /// No description provided for @heightHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập chiều cao'**
  String get heightHint;

  /// No description provided for @weight.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get weight;

  /// No description provided for @weightUnit.
  ///
  /// In vi, this message translates to:
  /// **'kg'**
  String get weightUnit;

  /// No description provided for @weightHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập cân nặng'**
  String get weightHint;

  /// No description provided for @age.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi'**
  String get age;

  /// No description provided for @ageHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tuổi'**
  String get ageHint;

  /// No description provided for @gender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get male;

  /// No description provided for @female.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get female;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get next;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @start.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get start;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get done;

  /// No description provided for @goalLose.
  ///
  /// In vi, this message translates to:
  /// **'Giảm cân'**
  String get goalLose;

  /// No description provided for @goalLoseDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giảm 20% lượng calo'**
  String get goalLoseDesc;

  /// No description provided for @goalMaintain.
  ///
  /// In vi, this message translates to:
  /// **'Duy trì'**
  String get goalMaintain;

  /// No description provided for @goalMaintainDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giữ nguyên cân nặng'**
  String get goalMaintainDesc;

  /// No description provided for @goalGain.
  ///
  /// In vi, this message translates to:
  /// **'Tăng cân'**
  String get goalGain;

  /// No description provided for @goalGainDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tăng 20% lượng calo'**
  String get goalGainDesc;

  /// No description provided for @homeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get homeTitle;

  /// No description provided for @cameraCard.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get cameraCard;

  /// No description provided for @cameraCardDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quét món ăn'**
  String get cameraCardDesc;

  /// No description provided for @chatbotCard.
  ///
  /// In vi, this message translates to:
  /// **'Chatbot'**
  String get chatbotCard;

  /// No description provided for @chatbotCardDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi về dinh dưỡng'**
  String get chatbotCardDesc;

  /// No description provided for @caloriesIntake.
  ///
  /// In vi, this message translates to:
  /// **'Nạp vào'**
  String get caloriesIntake;

  /// No description provided for @caloriesBurned.
  ///
  /// In vi, this message translates to:
  /// **'Đốt cháy'**
  String get caloriesBurned;

  /// No description provided for @caloriesNet.
  ///
  /// In vi, this message translates to:
  /// **'Thực tế'**
  String get caloriesNet;

  /// No description provided for @kcal.
  ///
  /// In vi, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @targetProgress.
  ///
  /// In vi, this message translates to:
  /// **'mục tiêu'**
  String get targetProgress;

  /// No description provided for @upcomingGym.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tập sắp tới'**
  String get upcomingGym;

  /// No description provided for @noUpcomingGym.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch tập'**
  String get noUpcomingGym;

  /// No description provided for @addGymSession.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lịch tập'**
  String get addGymSession;

  /// No description provided for @viewHistory.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch sử'**
  String get viewHistory;

  /// No description provided for @chatbotTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chatbot Dinh Dưỡng'**
  String get chatbotTitle;

  /// No description provided for @chatbotHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập món ăn (VD: 200g phở bò)'**
  String get chatbotHint;

  /// No description provided for @chatbotPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi về bất kỳ món ăn nào...'**
  String get chatbotPlaceholder;

  /// No description provided for @addToDiary.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào nhật ký'**
  String get addToDiary;

  /// No description provided for @added.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm!'**
  String get added;

  /// No description provided for @scanning.
  ///
  /// In vi, this message translates to:
  /// **'Đang quét...'**
  String get scanning;

  /// No description provided for @scanResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả'**
  String get scanResult;

  /// No description provided for @scanAgain.
  ///
  /// In vi, this message translates to:
  /// **'Quét lại'**
  String get scanAgain;

  /// No description provided for @protein.
  ///
  /// In vi, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In vi, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In vi, this message translates to:
  /// **'Chất béo'**
  String get fat;

  /// No description provided for @historyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get historyTitle;

  /// No description provided for @selectDate.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày'**
  String get selectDate;

  /// No description provided for @noDataForDate.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noDataForDate;

  /// No description provided for @mealsToday.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn hôm nay'**
  String get mealsToday;

  /// No description provided for @gymScheduler.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tập gym'**
  String get gymScheduler;

  /// No description provided for @selectTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ'**
  String get selectTime;

  /// No description provided for @startTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ bắt đầu'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ kết thúc'**
  String get endTime;

  /// No description provided for @duration.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get duration;

  /// No description provided for @durationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút'**
  String durationMinutes(Object count);

  /// No description provided for @durationHours.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ'**
  String durationHours(Object count);

  /// No description provided for @gymType.
  ///
  /// In vi, this message translates to:
  /// **'Loại bài tập'**
  String get gymType;

  /// No description provided for @estimatedCalories.
  ///
  /// In vi, this message translates to:
  /// **'Calo đốt cháy (ước tính)'**
  String get estimatedCalories;

  /// No description provided for @caloriesPerHour.
  ///
  /// In vi, this message translates to:
  /// **'kcal/giờ'**
  String get caloriesPerHour;

  /// No description provided for @markComplete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get markComplete;

  /// No description provided for @completed.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get completed;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ tối'**
  String get darkMode;

  /// No description provided for @darkModeOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get darkModeOff;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get selectLanguage;

  /// No description provided for @country.
  ///
  /// In vi, this message translates to:
  /// **'Quốc gia'**
  String get country;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get notificationsDisabled;

  /// No description provided for @testNotification.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thông báo'**
  String get testNotification;

  /// No description provided for @testNotificationDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi thông báo test ngay'**
  String get testNotificationDesc;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @bodyInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cơ thể'**
  String get bodyInfo;

  /// No description provided for @currentGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu hiện tại'**
  String get currentGoal;

  /// No description provided for @stats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get stats;

  /// No description provided for @totalMeals.
  ///
  /// In vi, this message translates to:
  /// **'Tổng bữa ăn'**
  String get totalMeals;

  /// No description provided for @totalWorkouts.
  ///
  /// In vi, this message translates to:
  /// **'Tổng buổi tập'**
  String get totalWorkouts;

  /// No description provided for @streakDays.
  ///
  /// In vi, this message translates to:
  /// **'Ngày liên tiếp'**
  String get streakDays;

  /// No description provided for @about.
  ///
  /// In vi, this message translates to:
  /// **'Về ứng dụng'**
  String get about;

  /// No description provided for @version.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get version;

  /// No description provided for @rateApp.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá ứng dụng'**
  String get rateApp;

  /// No description provided for @rateAppDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ trải nghiệm của bạn'**
  String get rateAppDesc;

  /// No description provided for @shareApp.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ứng dụng'**
  String get shareApp;

  /// No description provided for @shareAppDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu cho bạn bè'**
  String get shareAppDesc;

  /// No description provided for @data.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu'**
  String get data;

  /// No description provided for @exportData.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get exportData;

  /// No description provided for @exportDataDesc.
  ///
  /// In vi, this message translates to:
  /// **'Lưu dữ liệu ra file'**
  String get exportDataDesc;

  /// No description provided for @clearAllData.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả dữ liệu'**
  String get clearAllData;

  /// No description provided for @clearAllDataDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn tất cả dữ liệu'**
  String get clearAllDataDesc;

  /// No description provided for @clearDataConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả dữ liệu?'**
  String get clearDataConfirm;

  /// No description provided for @clearDataWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác. Tất cả bữa ăn, lịch tập và cài đặt sẽ bị xóa.'**
  String get clearDataWarning;

  /// No description provided for @privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đọc chính sách bảo mật'**
  String get privacyPolicyDesc;

  /// No description provided for @termsOfService.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get termsOfService;

  /// No description provided for @termsOfServiceDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đọc điều khoản sử dụng'**
  String get termsOfServiceDesc;

  /// No description provided for @legal.
  ///
  /// In vi, this message translates to:
  /// **'Pháp lý'**
  String get legal;

  /// No description provided for @sunday.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ hai'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ ba'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ tư'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ năm'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ sáu'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ bảy'**
  String get saturday;

  /// No description provided for @errorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get errorUnknown;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @bmrCalculated.
  ///
  /// In vi, this message translates to:
  /// **'BMR của bạn'**
  String get bmrCalculated;

  /// No description provided for @dailyTarget.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu hàng ngày'**
  String get dailyTarget;

  /// No description provided for @bmrInfo.
  ///
  /// In vi, this message translates to:
  /// **'BMR là lượng calo cơ thể đốt khi nghỉ ngơi'**
  String get bmrInfo;

  /// No description provided for @welcome.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào'**
  String get welcome;

  /// No description provided for @goodMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối'**
  String get goodEvening;

  /// No description provided for @workoutCard.
  ///
  /// In vi, this message translates to:
  /// **'Tập luyện'**
  String get workoutCard;

  /// No description provided for @workoutCardDesc.
  ///
  /// In vi, this message translates to:
  /// **'12 tuần giảm cân'**
  String get workoutCardDesc;

  /// No description provided for @workoutProgram.
  ///
  /// In vi, this message translates to:
  /// **'Chương Trình Tập Luyện'**
  String get workoutProgram;

  /// No description provided for @weekLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get weekLabel;

  /// No description provided for @scheduleThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Lịch tuần này'**
  String get scheduleThisWeek;

  /// No description provided for @todayLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayLabel;

  /// No description provided for @exercises.
  ///
  /// In vi, this message translates to:
  /// **'Bài tập'**
  String get exercises;

  /// No description provided for @minutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get minutes;

  /// No description provided for @calories.
  ///
  /// In vi, this message translates to:
  /// **'Calo'**
  String get calories;

  /// No description provided for @watchVideo.
  ///
  /// In vi, this message translates to:
  /// **'Xem video hướng dẫn'**
  String get watchVideo;

  /// No description provided for @restDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày nghỉ'**
  String get restDay;

  /// No description provided for @restDayNote.
  ///
  /// In vi, this message translates to:
  /// **'Nghỉ ngơi để cơ thể phục hồi'**
  String get restDayNote;

  /// No description provided for @instructions.
  ///
  /// In vi, this message translates to:
  /// **'Cách thực hiện'**
  String get instructions;

  /// No description provided for @videoTutorials.
  ///
  /// In vi, this message translates to:
  /// **'Video hướng dẫn'**
  String get videoTutorials;

  /// No description provided for @tips.
  ///
  /// In vi, this message translates to:
  /// **'Mẹo hay'**
  String get tips;

  /// No description provided for @progress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ'**
  String get progress;

  /// No description provided for @set.
  ///
  /// In vi, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @completedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get completedLabel;

  /// No description provided for @nextSet.
  ///
  /// In vi, this message translates to:
  /// **'Set tiếp theo'**
  String get nextSet;

  /// No description provided for @previousSet.
  ///
  /// In vi, this message translates to:
  /// **'Set trước'**
  String get previousSet;

  /// No description provided for @complete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get complete;

  /// No description provided for @successMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc! Bạn đã hoàn thành!'**
  String get successMessage;

  /// No description provided for @scanFood.
  ///
  /// In vi, this message translates to:
  /// **'Quét món ăn'**
  String get scanFood;

  /// No description provided for @takePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get takePhoto;

  /// No description provided for @analyzing.
  ///
  /// In vi, this message translates to:
  /// **'Đang phân tích...'**
  String get analyzing;

  /// No description provided for @recognitionResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả nhận diện'**
  String get recognitionResult;

  /// No description provided for @retake.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại'**
  String get retake;

  /// No description provided for @addToDiaryAction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào nhật ký'**
  String get addToDiaryAction;

  /// No description provided for @noFoodDetected.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận diện được thức ăn trong ảnh'**
  String get noFoodDetected;

  /// No description provided for @aiConfidence.
  ///
  /// In vi, this message translates to:
  /// **'Độ tin cậy AI'**
  String get aiConfidence;

  /// No description provided for @notificationScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt thông báo'**
  String get notificationScheduled;

  /// No description provided for @reminderTime.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo sẽ gửi lúc'**
  String get reminderTime;

  /// No description provided for @sessionScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt lịch tập'**
  String get sessionScheduled;

  /// No description provided for @gymChest.
  ///
  /// In vi, this message translates to:
  /// **'Gym ngực'**
  String get gymChest;

  /// No description provided for @gymBack.
  ///
  /// In vi, this message translates to:
  /// **'Gym lưng'**
  String get gymBack;

  /// No description provided for @gymShoulders.
  ///
  /// In vi, this message translates to:
  /// **'Gym vai'**
  String get gymShoulders;

  /// No description provided for @gymLegs.
  ///
  /// In vi, this message translates to:
  /// **'Gym chân'**
  String get gymLegs;

  /// No description provided for @gymArms.
  ///
  /// In vi, this message translates to:
  /// **'Gym tay'**
  String get gymArms;

  /// No description provided for @gymAbs.
  ///
  /// In vi, this message translates to:
  /// **'Gym bụng'**
  String get gymAbs;

  /// No description provided for @gymFullBody.
  ///
  /// In vi, this message translates to:
  /// **'Full Body'**
  String get gymFullBody;

  /// No description provided for @gymRunning.
  ///
  /// In vi, this message translates to:
  /// **'Chạy bộ'**
  String get gymRunning;

  /// No description provided for @gymWalking.
  ///
  /// In vi, this message translates to:
  /// **'Đi bộ'**
  String get gymWalking;

  /// No description provided for @gymSwimming.
  ///
  /// In vi, this message translates to:
  /// **'Bơi lội'**
  String get gymSwimming;

  /// No description provided for @gymCycling.
  ///
  /// In vi, this message translates to:
  /// **'Đạp xe'**
  String get gymCycling;

  /// No description provided for @gymYoga.
  ///
  /// In vi, this message translates to:
  /// **'Yoga'**
  String get gymYoga;

  /// No description provided for @gymHiit.
  ///
  /// In vi, this message translates to:
  /// **'HIIT'**
  String get gymHiit;

  /// No description provided for @gymCardio.
  ///
  /// In vi, this message translates to:
  /// **'Cardio'**
  String get gymCardio;

  /// No description provided for @gymStretching.
  ///
  /// In vi, this message translates to:
  /// **'Giãn cơ'**
  String get gymStretching;

  /// No description provided for @gymCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh'**
  String get gymCustom;

  /// No description provided for @madeWithLove.
  ///
  /// In vi, this message translates to:
  /// **'Made with ❤️ in Vietnam'**
  String get madeWithLove;

  /// No description provided for @waterIntake.
  ///
  /// In vi, this message translates to:
  /// **'Nước uống'**
  String get waterIntake;

  /// No description provided for @waterTarget.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu nước'**
  String get waterTarget;

  /// No description provided for @waterRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount}ml'**
  String waterRemaining(Object amount);

  /// No description provided for @waterGoalReached.
  ///
  /// In vi, this message translates to:
  /// **'Đã đạt mục tiêu!'**
  String get waterGoalReached;

  /// No description provided for @waterAddCustom.
  ///
  /// In vi, this message translates to:
  /// **'Thêm nước'**
  String get waterAddCustom;

  /// No description provided for @waterAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get waterAdd;

  /// No description provided for @waterTipGoalReached.
  ///
  /// In vi, this message translates to:
  /// **'Tuyệt vời! Bạn đã uống đủ nước hôm nay!'**
  String get waterTipGoalReached;

  /// No description provided for @waterTipMorning.
  ///
  /// In vi, this message translates to:
  /// **'Hãy uống nước vào buổi sáng để bắt đầu ngày mới!'**
  String get waterTipMorning;

  /// No description provided for @waterTipAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Đừng quên uống nước vào buổi chiều!'**
  String get waterTipAfternoon;

  /// No description provided for @waterTipEvening.
  ///
  /// In vi, this message translates to:
  /// **'Uống thêm nước trước khi đi ngủ!'**
  String get waterTipEvening;

  /// No description provided for @waterTipKeepGoing.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục uống nước đều đặn!'**
  String get waterTipKeepGoing;

  /// No description provided for @waterDailyTarget.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu hàng ngày'**
  String get waterDailyTarget;

  /// No description provided for @waterHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử uống nước'**
  String get waterHistory;

  /// No description provided for @waterStats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê nước'**
  String get waterStats;

  /// No description provided for @waterWeeklyAverage.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình tuần'**
  String get waterWeeklyAverage;

  /// No description provided for @waterDaysReachedGoal.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đạt mục tiêu'**
  String get waterDaysReachedGoal;

  /// No description provided for @weightTracking.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get weightTracking;

  /// No description provided for @weightCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng hiện tại'**
  String get weightCurrent;

  /// No description provided for @weightGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get weightGoal;

  /// No description provided for @weightUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật cân nặng'**
  String get weightUpdate;

  /// No description provided for @weightHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử cân nặng'**
  String get weightHistory;

  /// No description provided for @weightChange.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi'**
  String get weightChange;

  /// No description provided for @weightTrend.
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng'**
  String get weightTrend;

  /// No description provided for @weightTrendUp.
  ///
  /// In vi, this message translates to:
  /// **'Tăng'**
  String get weightTrendUp;

  /// No description provided for @weightTrendDown.
  ///
  /// In vi, this message translates to:
  /// **'Giảm'**
  String get weightTrendDown;

  /// No description provided for @weightTrendStable.
  ///
  /// In vi, this message translates to:
  /// **'Ổn định'**
  String get weightTrendStable;

  /// No description provided for @bmi.
  ///
  /// In vi, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @bmiUnderweight.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu cân'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In vi, this message translates to:
  /// **'Thừa cân'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In vi, this message translates to:
  /// **'Béo phì'**
  String get bmiObese;

  /// No description provided for @tapToUpdateWeight.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn để cập nhật cân nặng'**
  String get tapToUpdateWeight;

  /// No description provided for @achievements.
  ///
  /// In vi, this message translates to:
  /// **'Thành tựu'**
  String get achievements;

  /// No description provided for @allAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thành tựu'**
  String get allAchievements;

  /// No description provided for @unlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở khóa'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở khóa'**
  String get locked;

  /// No description provided for @secretAchievement.
  ///
  /// In vi, this message translates to:
  /// **'Thành tựu bí mật'**
  String get secretAchievement;

  /// No description provided for @keepUsingToDiscover.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục sử dụng app để khám phá'**
  String get keepUsingToDiscover;

  /// No description provided for @newAchievement.
  ///
  /// In vi, this message translates to:
  /// **'Thành tựu mới!'**
  String get newAchievement;

  /// No description provided for @excellent.
  ///
  /// In vi, this message translates to:
  /// **'Tuyệt vời!'**
  String get excellent;

  /// No description provided for @xpRemaining.
  ///
  /// In vi, this message translates to:
  /// **'XP còn lại'**
  String get xpRemaining;

  /// No description provided for @completion.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get completion;

  /// No description provided for @levelBeginner.
  ///
  /// In vi, this message translates to:
  /// **'Người mới'**
  String get levelBeginner;

  /// No description provided for @levelNovice.
  ///
  /// In vi, this message translates to:
  /// **'Tập sự'**
  String get levelNovice;

  /// No description provided for @levelIntermediate.
  ///
  /// In vi, this message translates to:
  /// **'Trung cấp'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cao'**
  String get levelAdvanced;

  /// No description provided for @levelExpert.
  ///
  /// In vi, this message translates to:
  /// **'Chuyên gia'**
  String get levelExpert;

  /// No description provided for @levelMaster.
  ///
  /// In vi, this message translates to:
  /// **'Bậc thầy'**
  String get levelMaster;

  /// No description provided for @levelLegend.
  ///
  /// In vi, this message translates to:
  /// **'Huyền thoại'**
  String get levelLegend;

  /// No description provided for @achievementStreak3.
  ///
  /// In vi, this message translates to:
  /// **'3 ngày liên tiếp'**
  String get achievementStreak3;

  /// No description provided for @achievementStreak7.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày liên tiếp'**
  String get achievementStreak7;

  /// No description provided for @achievementStreak14.
  ///
  /// In vi, this message translates to:
  /// **'14 ngày liên tiếp'**
  String get achievementStreak14;

  /// No description provided for @achievementStreak30.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày liên tiếp'**
  String get achievementStreak30;

  /// No description provided for @achievementStreak100.
  ///
  /// In vi, this message translates to:
  /// **'100 ngày liên tiếp'**
  String get achievementStreak100;

  /// No description provided for @achievementCalorieFirst.
  ///
  /// In vi, this message translates to:
  /// **'Bữa ăn đầu tiên'**
  String get achievementCalorieFirst;

  /// No description provided for @achievementCalorie10.
  ///
  /// In vi, this message translates to:
  /// **'10 bữa ăn'**
  String get achievementCalorie10;

  /// No description provided for @achievementCalorie50.
  ///
  /// In vi, this message translates to:
  /// **'50 bữa ăn'**
  String get achievementCalorie50;

  /// No description provided for @achievementCalorie100.
  ///
  /// In vi, this message translates to:
  /// **'100 bữa ăn'**
  String get achievementCalorie100;

  /// No description provided for @achievementWaterFirst.
  ///
  /// In vi, this message translates to:
  /// **'Uống nước đầu tiên'**
  String get achievementWaterFirst;

  /// No description provided for @achievementWater7.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày uống đủ nước'**
  String get achievementWater7;

  /// No description provided for @achievementWater30.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày uống đủ nước'**
  String get achievementWater30;

  /// No description provided for @achievementWorkoutFirst.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tập đầu tiên'**
  String get achievementWorkoutFirst;

  /// No description provided for @achievementWorkout10.
  ///
  /// In vi, this message translates to:
  /// **'10 buổi tập'**
  String get achievementWorkout10;

  /// No description provided for @achievementWorkout50.
  ///
  /// In vi, this message translates to:
  /// **'50 buổi tập'**
  String get achievementWorkout50;

  /// No description provided for @achievementWeightFirst.
  ///
  /// In vi, this message translates to:
  /// **'Cân đầu tiên'**
  String get achievementWeightFirst;

  /// No description provided for @achievementWeightGoal.
  ///
  /// In vi, this message translates to:
  /// **'Đạt mục tiêu cân nặng'**
  String get achievementWeightGoal;

  /// No description provided for @achievementEarlyBird.
  ///
  /// In vi, this message translates to:
  /// **'Chim sớm'**
  String get achievementEarlyBird;

  /// No description provided for @achievementNightOwl.
  ///
  /// In vi, this message translates to:
  /// **'Cú đêm'**
  String get achievementNightOwl;

  /// No description provided for @barcodeScanner.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã vạch'**
  String get barcodeScanner;

  /// No description provided for @barcodeScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã vạch'**
  String get barcodeScan;

  /// No description provided for @barcodeProduct.
  ///
  /// In vi, this message translates to:
  /// **'Sản phẩm'**
  String get barcodeProduct;

  /// No description provided for @barcodePlaceInFrame.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mã vạch vào khung hình'**
  String get barcodePlaceInFrame;

  /// No description provided for @barcodeSearching.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm sản phẩm...'**
  String get barcodeSearching;

  /// No description provided for @barcodeNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy sản phẩm'**
  String get barcodeNotFound;

  /// No description provided for @barcodeNutritionPer100g.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin dinh dưỡng (100g)'**
  String get barcodeNutritionPer100g;

  /// No description provided for @barcodeScanAgain.
  ///
  /// In vi, this message translates to:
  /// **'Quét lại'**
  String get barcodeScanAgain;

  /// No description provided for @barcodeWeight.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng'**
  String get barcodeWeight;

  /// No description provided for @barcodeCaloriesFor.
  ///
  /// In vi, this message translates to:
  /// **'Calories cho'**
  String get barcodeCaloriesFor;

  /// No description provided for @mealSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý món ăn'**
  String get mealSuggestions;

  /// No description provided for @suggestionBreakfast.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý bữa sáng'**
  String get suggestionBreakfast;

  /// No description provided for @suggestionLunch.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý bữa trưa'**
  String get suggestionLunch;

  /// No description provided for @suggestionDinner.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý bữa tối'**
  String get suggestionDinner;

  /// No description provided for @suggestionSnack.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý bữa phụ'**
  String get suggestionSnack;

  /// No description provided for @remainingCalories.
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount} kcal'**
  String remainingCalories(Object amount);

  /// No description provided for @suggestionReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do phù hợp'**
  String get suggestionReason;

  /// No description provided for @moreSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm gợi ý'**
  String get moreSuggestions;

  /// No description provided for @loadingSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải gợi ý...'**
  String get loadingSuggestions;

  /// No description provided for @addToLog.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get addToLog;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

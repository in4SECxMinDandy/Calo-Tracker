// English & Vietnamese Text for Workout Feature
// Use based on current locale

class WorkoutStrings {
  static String getTitle(String locale) {
    return locale == 'vi' ? '💪 Chương Trình Tập Luyện' : '💪 Workout Program';
  }

  static String getMotivationWeek(int week, String locale) {
    if (locale == 'vi') {
      if (week <= 2) {
        return "Tại sao mình tập vậy? Mệt quá!\n→ BÌNH THƯỜNG! Cơ thể đang thích nghi.";
      }
      if (week <= 4) {
        return "Vẫn chưa thấy giảm cân!\n→ KIÊN TRÌ! Mỡ giảm từ trong ra ngoài.";
      }
      if (week <= 6) {
        return "Ồ, quần áo rộng hơn rồi!\n→ ĐÚNG HƯỚNG! Cơ thể đang thay đổi.";
      }
      if (week <= 8) {
        return "Mọi người nhận xét mình khác đi!\n→ THÀNH CÔNG! Tiếp tục là được.";
      }
      return "Mình đã làm được!\n→ TỰ HÀO! Giờ là lúc duy trì và phát triển.";
    } else {
      if (week <= 2) {
        return "Why am I doing this? So tired!\n→ NORMAL! Your body is adapting.";
      }
      if (week <= 4) {
        return "Still no weight loss!\n→ KEEP GOING! Fat burns from inside out.";
      }
      if (week <= 6) {
        return "Oh, clothes feel looser!\n→ RIGHT TRACK! Body is changing.";
      }
      if (week <= 8) {
        return "People notice I've changed!\n→ SUCCESS! Keep it up.";
      }
      return "I did it!\n→ PROUD! Time to maintain and grow.";
    }
  }

  static String getWeekLabel(int week, String locale) {
    return locale == 'vi' ? 'Tuần $week/12' : 'Week $week/12';
  }

  static String getScheduleTitle(String locale) {
    return locale == 'vi' ? 'Lịch tuần này' : 'This Week\'s Schedule';
  }

  static String getTodayLabel(String locale) {
    return locale == 'vi' ? 'Hôm nay' : 'Today';
  }

  static String getExercisesLabel(String locale) {
    return locale == 'vi' ? 'Bài tập' : 'Exercises';
  }

  static String getMinutesLabel(String locale) {
    return locale == 'vi' ? 'Phút' : 'Minutes';
  }

  static String getCaloriesLabel(String locale) {
    return locale == 'vi' ? 'Calo' : 'Calories';
  }

  static String getWatchVideoLabel(String locale) {
    return locale == 'vi' ? 'Xem video hướng dẫn' : 'Watch tutorial video';
  }

  static String getRestDay(String locale) {
    return locale == 'vi' ? 'Ngày nghỉ' : 'Rest Day';
  }

  static String getRestDayNote(String locale) {
    return locale == 'vi'
        ? 'Nghỉ ngơi để cơ thể phục hồi'
        : 'Rest for body recovery';
  }

  static String getInstructionsLabel(String locale) {
    return locale == 'vi' ? 'Cách thực hiện' : 'Instructions';
  }

  static String getVideoTutorialLabel(String locale) {
    return locale == 'vi' ? 'Video hướng dẫn' : 'Video Tutorials';
  }

  static String getTipsLabel(String locale) {
    return locale == 'vi' ? 'Mẹo hay' : 'Useful Tips';
  }

  static String getProgressLabel(String locale) {
    return locale == 'vi' ? 'Tiến độ' : 'Progress';
  }

  static String getSetLabel(String locale) {
    return locale == 'vi' ? 'Set' : 'Set';
  }

  static String getCompletedLabel(String locale) {
    return locale == 'vi' ? 'Hoàn thành' : 'Completed';
  }

  static String getNextSetLabel(String locale) {
    return locale == 'vi' ? 'Set tiếp theo ▶' : 'Next Set ▶';
  }

  static String getPreviousSetLabel(String locale) {
    return locale == 'vi' ? '◀ Set trước' : '◀ Previous Set';
  }

  static String getCompleteLabel(String locale) {
    return locale == 'vi' ? 'Hoàn thành' : 'Complete';
  }

  static String getSuccessMessage(String locale) {
    return locale == 'vi'
        ? '🎉 Xuất sắc! Bạn đã hoàn thành!'
        : '🎉 Excellent! You completed it!';
  }
}

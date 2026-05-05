import 'package:flutter/material.dart';

class AppLocale {
  static const String defaultLocale = 'en';
  
  static final Map<String, Map<String, String>> _locales = {
    'en': {
      // General
      'app_name': 'Health Tracker',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'ok': 'OK',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      
      // Navigation
      'home': 'Home',
      'diary': 'Diary',
      'plans': 'Plans',
      'recipes': 'Recipes',
      'profile': 'Profile',
      'settings': 'Settings',
      
      // Diary
      'steps': 'Steps',
      'calories': 'Calories',
      'heart_rate': 'Heart Rate',
      'bpm': 'BPM',
      'sleep': 'Sleep',
      'water': 'Water',
      'weight': 'Weight',
      'nutrition': 'Nutrition',
      'today': 'Today',
      'activity': 'Activity',
      'distance': 'Distance',
      'measure_bpm': 'Measure Heart Rate',
      
      // Heart Rate
      'measuring': 'Measuring...',
      'place_finger': 'Place finger on camera',
      'finger_on_camera': 'Finger detected',
      'keep_still': 'Keep finger still',
      'measurement_complete': 'Measurement complete',
      'heart_normal': 'Normal',
      'heart_low': 'Low',
      'heart_high': 'High',
      'heart_advice_normal': 'Your heart is healthy! Maintain a healthy lifestyle to keep your heart strong.',
      'heart_advice_low': 'Low heart rate may be due to exercise, medication. If accompanied by dizziness, consult a doctor.',
      'heart_advice_high': 'High heart rate may be due to stress, caffeine. Rest and limit caffeine intake.',
      
      // Settings
      'language': 'Language',
      'english': 'English',
      'vietnamese': 'Vietnamese',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'notifications': 'Notifications',
      'about': 'About',
      'version': 'Version',
      'logout': 'Logout',
      'login': 'Login',
      
      // Food
      'add_meal': 'Add Meal',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snack',
      'search_food': 'Search food...',
      'calories_remaining': 'Calories Remaining',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      
      // Sleep
      'sleep_duration': 'Sleep Duration',
      'hours': 'hours',
      'go_to_sleep': 'Go to Sleep',
      'wake_up': 'Wake Up',
      'record_sleep': 'Record Sleep',
      
      // Water
      'water_intake': 'Water Intake',
      'glasses': 'glasses',
      'add_water': 'Add Water',
      'goal': 'Goal',
      
      // Weight
      'current_weight': 'Current Weight',
      'kg': 'kg',
      'add_weight': 'Add Weight',
      'goal_weight': 'Goal Weight',
      
      // Goal
      'goal_achieved': 'Goal Achieved!',
      'congratulations': 'Congratulations!',
    },
    
    'vi': {
      // General
      'app_name': 'Theo Dõi Sức Khỏe',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'edit': 'Sửa',
      'ok': 'OK',
      'error': 'Lỗi',
      'success': 'Thành công',
      'loading': 'Đang tải...',
      
      // Navigation
      'home': 'Trang chủ',
      'diary': 'Nhật ký',
      'plans': 'Kế hoạch',
      'recipes': 'Công thức',
      'profile': 'Hồ sơ',
      'settings': 'Cài đặt',
      
      // Diary
      'steps': 'Bước chân',
      'calories': 'Calories',
      'heart_rate': 'Nhịp tim',
      'bpm': 'BPM',
      'sleep': 'Giấc ngủ',
      'water': 'Nước',
      'weight': 'Cân nặng',
      'nutrition': 'Dinh dưỡng',
      'today': 'Hôm nay',
      'activity': 'Hoạt động',
      'distance': 'Khoảng cách',
      'measure_bpm': 'Đo nhịp tim',
      
      // Heart Rate
      'measuring': 'Đang đo...',
      'place_finger': 'Đặt ngón tay lên camera',
      'finger_on_camera': 'Đã phát hiện ngón tay',
      'keep_still': 'Giữ yên ngón tay',
      'measurement_complete': 'Đo xong',
      'heart_normal': 'Bình thường',
      'heart_low': 'Thấp',
      'heart_high': 'Cao',
      'heart_advice_normal': 'Tim bạn khỏe mạnh! Duy trì lối sống lành mạnh để giữ tim khỏe mạnh.',
      'heart_advice_low': 'Nhịp tim thấp có thể do tập thể dục hoặc dùng thuốc. Nếu kèm chóng mặt, hãy khám bác sĩ.',
      'heart_advice_high': 'Nhịp tim cao có thể do stress, caffeine. Nghỉ ngơi và hạn chế caffeine.',
      
      // Settings
      'language': 'Ngôn ngữ',
      'english': 'Tiếng Anh',
      'vietnamese': 'Tiếng Việt',
      'theme': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'light_mode': 'Chế độ sáng',
      'notifications': 'Thông báo',
      'about': 'Giới thiệu',
      'version': 'Phiên bản',
      'logout': 'Đăng xuất',
      'login': 'Đăng nhập',
      
      // Food
      'add_meal': 'Thêm bữa ăn',
      'breakfast': 'Sáng',
      'lunch': 'Trưa',
      'dinner': 'Tối',
      'snack': 'Xế',
      'search_food': 'Tìm thực phẩm...',
      'calories_remaining': 'Calories còn lại',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Chất béo',
      
      // Sleep
      'sleep_duration': 'Thời gian ngủ',
      'hours': 'giờ',
      'go_to_sleep': 'Ngủ',
      'wake_up': 'Thức dậy',
      'record_sleep': 'Ghi giấc ngủ',
      
      // Water
      'water_intake': 'Lượng nước',
      'glasses': 'ly',
      'add_water': 'Thêm nước',
      'goal': 'Mục tiêu',
      
      // Weight
      'current_weight': 'Cân nặng hiện tại',
      'kg': 'kg',
      'add_weight': 'Thêm cân nặng',
      'goal_weight': 'Cân nặng mục tiêu',
      
      // Goal
      'goal_achieved': 'Đạt mục tiêu!',
      'congratulations': 'Chúc mừng!',
    },
  };

  static String get(String key, {String locale = defaultLocale}) {
    return _locales[locale]?[key] ?? _locales[defaultLocale]?[key] ?? key;
  }

  static List<String> get supportedLocales => _locales.keys.toList();

  static String getLocaleName(String locale) {
    switch (locale) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
      default:
        return 'English';
    }
  }
}

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  String translate(String key) {
    return AppLocale.get(key, locale: locale.languageCode);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
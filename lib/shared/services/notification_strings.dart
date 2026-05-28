import 'package:shared_preferences/shared_preferences.dart';

class NotificationStrings {
  static String _langCode = 'vi';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _langCode = prefs.getString('language') ?? 'vi';
  }

  static Future<void> refresh() async {
    await load();
  }

  static String get waterReminderTitle =>
      _langCode == 'vi' ? '\u{1F4A7} Uống nước' : '\u{1F4A7} Drink water';

  static String get waterReminderBody =>
      _langCode == 'vi' ? 'Đã đến giờ uống nước!' : 'Time to drink water!';

  static String get walkReminderTitle =>
      _langCode == 'vi' ? '\u{1F6B6} Đi bộ thôi!' : '\u{1F6B6} Time to move!';

  static String get walkReminderBody =>
      _langCode == 'vi'
          ? 'Bạn đã ngồi lâu quá rồi.\nHãy đi bộ một chút để giữ sức khỏe.'
          : 'You\'ve been inactive for a while.\nTake a short walk to stay healthy.';

  static String get heartReminderTitle =>
      _langCode == 'vi' ? '\u{2764}\u{FE0F} Đo nhịp tim' : '\u{2764}\u{FE0F} Check your heart rate';

  static String get heartReminderBody =>
      _langCode == 'vi'
          ? 'Đã đến lúc đo nhịp tim của bạn.\nHãy theo dõi sức khỏe nhé!'
          : 'It\'s time to measure your heart rate.\nStay on top of your health!';

  static String get meditationReminderTitle =>
      _langCode == 'vi' ? '\u{1F9D8} Thư giãn' : '\u{1F9D8} Time to relax';

  static String get meditationReminderBody =>
      _langCode == 'vi'
          ? 'Hãy dành chút thời gian để thư giãn và hít thở.\nThiền ngắn có thể giúp ích.'
          : 'Take a moment to relax and breathe.\nA short meditation can help.';

  static String get sleepReminderTitle =>
      _langCode == 'vi' ? '\u{1F634} Đến giờ ngủ' : '\u{1F634} Time to sleep';

  static String get sleepReminderBody =>
      _langCode == 'vi'
          ? 'Đã muộn rồi.\nHãy chuẩn bị đi ngủ để nghỉ ngơi nhé.'
          : 'It\'s getting late.\nPrepare for sleep and rest well tonight.';

  // Default reminder titles (for ReminderService initial defaults)
  String get defaultDrinkWater => _langCode == 'vi' ? 'Uống nước' : 'Drink water';
  String get defaultDrinkWaterSub => _langCode == 'vi' ? 'Nhắc nhở uống đủ nước' : 'Reminder to drink enough water';
  String get defaultWalk => _langCode == 'vi' ? 'Đi bộ sáng' : 'Morning walk';
  String get defaultWalkSub => _langCode == 'vi' ? 'Đi bộ 30 phút mỗi sáng' : 'Walk 30 minutes every morning';
  String get defaultHeartRate => _langCode == 'vi' ? 'Đo nhịp tim' : 'Measure heart rate';
  String get defaultHeartRateSub => _langCode == 'vi' ? 'Kiểm tra chỉ số tim mỗi ngày' : 'Check heart rate daily';
  String get defaultMeditation => _langCode == 'vi' ? 'Thiền định' : 'Meditation';
  String get defaultMeditationSub => _langCode == 'vi' ? 'Thư giãn tinh thần 10 phút' : 'Relax your mind for 10 minutes';
  String get defaultSleep => _langCode == 'vi' ? 'Đi ngủ' : 'Go to sleep';
  String get defaultSleepSub => _langCode == 'vi' ? 'Chuẩn bị đi ngủ đúng giờ' : 'Prepare for bed on time';
}

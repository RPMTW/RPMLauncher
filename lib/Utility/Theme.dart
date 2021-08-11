import 'package:RPMLauncher/Utility/i18n.dart';

class ThemeUtility {
  static const int Dark = 0;
  static const int Light = 1;

  static String toI18nString(int themeId) {
    switch (themeId) {
      case Dark:
        return i18n.Format('settings.appearance.theme.dark');
      case Light:
        return i18n.Format('settings.appearance.theme.light');
      default:
        return "Unknown";
    }
  }
}
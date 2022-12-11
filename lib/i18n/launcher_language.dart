import 'package:flag/flag.dart';

enum LauncherLanguage {
  americanEnglish('English (US)', 'en_us', FlagsCode.US),
  traditionalChineseTW('繁體中文 (台灣)', 'zh_tw', FlagsCode.TW),
  traditionalChineseHK('繁體中文 (香港)', 'zh_hk', FlagsCode.HK),
  simplifiedChineseCN('简体中文 (中国)', 'zh_cn', FlagsCode.CN),
  japanese('日本語', 'ja_jp', FlagsCode.JP),
  russian('Русский', 'ru_ru', FlagsCode.RU);

  final String name;
  final String code;
  final FlagsCode flagCode;

  static const LauncherLanguage defaultLanguage =
      LauncherLanguage.americanEnglish;

  const LauncherLanguage(this.name, this.code, this.flagCode);

  Flag getFlagWidget({double height = 30, double width = 30}) =>
      Flag.fromCode(flagCode, height: height, width: width);
}

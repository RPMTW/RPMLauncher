import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Utility/Config.dart';
import 'package:flutter/services.dart';

Map _LanguageMap = {};

class i18n {
  static List<String> LanguageNames = [
    'English',
    '繁體中文 (台灣)',
    '繁體中文 (香港)',
    '简体中文',
    '日本語'
  ];
  static List<String> LanguageCodes = [
    'en_us',
    'zh_tw',
    'zh_hk',
    'zh_cn',
    'ja_jp'
  ];

  static init() {
    _LoadLanguageMap();
  }

  static void _LoadLanguageMap() async {
    for (var i in LanguageCodes) {
      String data = await rootBundle.loadString('lang/${i}.json');
      _LanguageMap[i] = await json.decode(data);
    }
  }

  static String Format(String key) {
    var value;
    try {
      value = _LanguageMap[Config.GetValue("lang_code")]![key];
      if (value == null) {
        value = _LanguageMap["zh_tw"]![key]; //如果找不到本地化文字，將使用預設語言
      }
    } catch (err) {
      value = key;
    }
    return value;
  }

  static Map GetLanguageMap() {
    return _LanguageMap;
  }

  static String GetLanguageCode() {
    if (LanguageCodes.contains(Platform.localeName.toLowerCase())) {
      return Platform.localeName.toLowerCase();
    } else {
      return "zh_tw";
    }
  }
}

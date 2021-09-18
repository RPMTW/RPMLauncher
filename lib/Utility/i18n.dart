import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:flutter/services.dart';

Map _LanguageMap = {};

class i18n {
  static List<String> LanguageNames = [
    'English (US)',
    '繁體中文 (台灣)',
    '繁體中文 (香港)',
    '简体中文 (中国)',
    '日本語'
  ];
  static List<String> LanguageCodes = [
    'en_us',
    'zh_tw',
    'zh_hk',
    'zh_cn',
    'ja_jp'
  ];

  static Future<void> init() async {
    await _loadLanguageMap();
  }

  static Future<void> _loadLanguageMap() async {
    for (var i in LanguageCodes) {
      String data = await rootBundle.loadString('lang/${i}.json');
      _LanguageMap[i] = await json.decode(data);
    }
  }

  static String format(String key) {
    var value;
    try {
      value = _LanguageMap[Config.getValue("lang_code")]![key];
      if (value == null) {
        value = _LanguageMap["zh_tw"]![key]; //如果找不到本地化文字，將使用預設語言
      }
    } catch (err) {
      value = key;
    }
    return value;
  }

  static Map getLanguageMap() {
    return _LanguageMap;
  }

  static String getLanguageCode() {
    if (LanguageCodes.contains(Platform.localeName.toLowerCase())) {
      return Platform.localeName.toLowerCase();
    } else {
      return "zh_tw";
    }
  }

  static Widget selectorWidget() {
    String LanguageNamesValue = i18n.LanguageNames[
        i18n.LanguageCodes.indexOf(Config.getValue("lang_code"))];
    return StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            i18n.format("settings.appearance.language.title"),
            style: TextStyle(fontSize: 20.0, color: Colors.lightBlue),
          ),
          DropdownButton<String>(
            value: LanguageNamesValue,
            onChanged: (String? newValue) {
              setState(() {
                LanguageNamesValue = newValue!;
                Config.change("lang_code",
                    LanguageCodes[LanguageNames.indexOf(LanguageNamesValue)]);
              });
            },
            items: LanguageNames.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}

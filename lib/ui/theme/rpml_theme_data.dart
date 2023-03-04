import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';

class RPMLThemeData {
  final RPMLThemeType type;
  final Color mainColor;
  final Color primaryColor;

  final Color backgroundColor;
  final Color dialogBackgroundColor;

  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const RPMLThemeData({
    required this.type,
    required this.mainColor,
    required this.primaryColor,
    required this.backgroundColor,
    required this.dialogBackgroundColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  });

  factory RPMLThemeData.byType(RPMLThemeType type) {
    switch (type) {
      case RPMLThemeType.light:
        return RPMLThemeData.light();
      case RPMLThemeType.dark:
        return RPMLThemeData.dark();
    }
  }

  factory RPMLThemeData.light() {
    return const RPMLThemeData(
        type: RPMLThemeType.light,
        mainColor: Color.fromARGB(255, 148, 191, 168),
        primaryColor: Color(0XFF14AE5C),
        backgroundColor: Color.fromARGB(255, 177, 197, 174),
        dialogBackgroundColor: Color.fromARGB(255, 185, 232, 207),
        textColor: Colors.black,
        subTextColor: Colors.black87,
        borderColor: Color(0XFF8F8F8F));
  }

  factory RPMLThemeData.dark() {
    return const RPMLThemeData(
        type: RPMLThemeType.dark,
        mainColor: Colors.black,
        primaryColor: Color(0XFF14AE5C),
        backgroundColor: Color(0xFF1E1E1E),
        dialogBackgroundColor: Color(0XFF2F2F2F),
        textColor: Color(0xFFFFFFFF),
        subTextColor: Colors.white54,
        borderColor: Color(0XFF56514D));
  }
}

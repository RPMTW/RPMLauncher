import 'dart:io';

import 'package:dio_http/dio_http.dart';
import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/main.dart';

class Analytics {
  String trackingId = "G-T5LGYPGM5V";

  late Dio dio;
  late String _clientId;

  Analytics() {
    _clientId = Config.getValue('ga_client_id');
    dio = Dio();
  }

  Future<void> ping({Duration? timeout}) async {
    await sendRawData(data: {'en': "user_engagement"});
  }

  Future<void> pageView(String page, String action) async {
    await sendRawData(
        data: {'en': "page_view&page_title=$page&method=$action"});
  }

  Future<void> sendRawData(
      {Map<String, String>? data, Duration? timeout}) async {
    if (LauncherInfo.isDebugMode) return;
    await Future.delayed(timeout ?? Duration(milliseconds: 150));
    Size _size;
    try {
      _size = MediaQuery.of(navigator.context).size;
    } catch (e) {
      _size = Size(1920, 1080);
    }
    Uri uri = Uri(
        scheme: "https",
        host: "www.google-analytics.com",
        path: "/g/collect",
        queryParameters: {
          "v": "2", //版本
          "sr": "${_size.width.toInt()}x${_size.height.toInt()}", //螢幕長寬
          "ul": getPlatformLocale(), //使用者語系
          "cid": _clientId, //客戶端ID,
          "tid": trackingId, //評估ID
        });

    await dio.post(uri.toString(),
        data: formatData(data),
        options: Options(
            contentType: Headers.textPlainContentType,
            headers: {"User-Agent": getUserAgent()}));
  }

  String formatData(Map<String, String>? data) {
    if (data != null) {
      String _data = "";
      data.forEach((key, value) {
        _data += "${key}=${value}\n";
      });
      return _data;
    } else {
      return "";
    }
  }

  String getUserAgent() {
    final locale = getPlatformLocale() ?? '';

    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Android; Mobile; ${locale})';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; U; CPU iPhone OS like Mac OS X; ${locale})';
    } else if (Platform.isMacOS) {
      return 'Mozilla/5.0 (Macintosh; Intel Mac OS X; Macintosh; ${locale})';
    } else if (Platform.isWindows) {
      return 'Mozilla/5.0 (Windows; Windows; Windows; ${locale})';
    } else if (Platform.isLinux) {
      return 'Mozilla/5.0 (Linux; Linux; Linux; ${locale})';
    } else {
      // Dart/1.8.0 (macos; macos; macos; en_US)
      var os = Platform.operatingSystem;
      return 'Dart/${Platform.version} (${os}; ${os}; ${os}; ${locale})';
    }
  }

  String? getPlatformLocale() {
    var locale = Platform.localeName;

    // Convert `en_US.UTF-8` to `en_US`.
    var index = locale.indexOf('.');
    if (index != -1) locale = locale.substring(0, index);

    // Convert `en_US` to `en-us`.
    locale = locale.replaceAll('_', '-').toLowerCase();

    return locale;
  }
}

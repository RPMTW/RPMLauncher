import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/main.dart';

class Analytics {
  String trackingId = "G-T5LGYPGM5V";

  late Dio dio;
  late String clientID;

  Analytics() {
    clientID = Config.getValue('ga_client_id');
    dio = Dio();
  }

  Future<void> ping({Duration? timeout}) async {
    await sendEvent(event: "user_engagement");
  }

  Future<void> firstVisit() async {
    await sendEvent(event: 'first_visit');
  }

  Future<void> pageView(String page, String action) async {
    await sendEvent(
      event: 'page_view',
      params: {
        'page_title': page,
        'method': action,
        'rwl_version': LauncherInfo.getFullVersion()
      },
    );
  }

  Future<void> sendEvent(
      {required String event,
      Map<String, String>? params,
      Duration? timeout}) async {
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
          "cid": clientID, //客戶端ID,
          "tid": trackingId, //評估ID,
          "uid": clientID, //使用者ID
          "an": "RPMLauncher",
          "av": LauncherInfo.getFullVersion(), //RPMLauncher 版本
          "platform": Platform.operatingSystem,
        });

    await dio.post(uri.toString(),
        data: formatData(event, params),
        options: Options(
            contentType: Headers.textPlainContentType,
            headers: {"User-Agent": getUserAgent()}));
  }

  String formatData(String event, Map<String, String>? params) {
    String _data = "";
    List<String> _list = [event];
    if (params != null) {
      params.forEach((key, value) {
        _list.add("$key=$value");
      });
    }
    _data = "en=${_list.join("&")}\n";
    return _data;
  }

  String getUserAgent() {
    final locale = getPlatformLocale() ?? '';
    String _v = LauncherInfo.getFullVersion();
    if (Platform.isAndroid) {
      return 'RPMLauncher/$_v (Android; Mobile; $locale)';
    } else if (Platform.isIOS) {
      return 'RPMLauncher/$_v (iPhone; U; CPU iPhone OS like Mac OS X; $locale)';
    } else if (Platform.isMacOS) {
      return 'RPMLauncher/$_v (Macintosh; Intel Mac OS X; Macintosh; $locale)';
    } else if (Platform.isWindows) {
      return 'RPMLauncher/$_v (Windows; Windows; Windows; $locale)';
    } else if (Platform.isLinux) {
      return 'RPMLauncher/$_v (Linux; Linux; Linux; $locale)';
    } else {
      // Dart/1.8.0 (macos; macos; macos; en_US)
      var os = Platform.operatingSystem;
      return 'Dart/${Platform.version} ($os; $os; $os; $locale)';
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

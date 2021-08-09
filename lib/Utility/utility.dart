import 'dart:convert';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Config.dart';
import 'i18n.dart';

class utility {
  static OpenFileManager(Dir) async {
    if (Dir.runtimeType == Directory) {
      CreateFolderOptimization(Dir);
    }
    if (Platform.isLinux) {
      await Process.run("xdg-open", [Dir.path]);
    } else if (Platform.isWindows) {
      await Process.run("start", ["file:///${Dir.path.replaceAll(" ", "%20")}"],
          runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run("open", [Dir.path]);
    }
  }

  static CreateFolderOptimization(Directory Dir) {
    if (!Dir.existsSync()) {
      Dir.createSync(recursive: true);
    }
  }

  static bool ParseLibRule(Map<String, dynamic> lib) {
    if (lib["rules"] != null) {
      if (lib["rules"].length > 1) {
        if (lib["rules"][0]["action"] == 'allow' &&
            lib["rules"][1]["action"] == 'disallow' &&
            lib["rules"][1]["os"]["name"] == 'osx') {
          return getOS() == 'osx';
        } else {
          return true;
        }
      } else {
        if (lib["rules"][0]["action"] == 'allow' &&
            lib["rules"][0]["os"] != null) return getOS() != 'osx';
      }
    }
    return false;
  }

  static String? getOS() {
    if (Platform.isWindows) {
      return "windows";
    }
    if (Platform.isLinux) {
      return "linux";
    }
    if (Platform.isMacOS) {
      return "osx";
    }
    return null;
  }

  static String GetSeparator() {
    if (Platform.isLinux) {
      return ":";
    } else {
      return ";";
    }
  }

  static Map ParseLibMaven(lib) {
    Map Result = {};
    String PackageName = lib["name"].toString().split(":")[0];
    String split_1 = lib["name"].toString().split("${PackageName}:").join("");
    String FileVersion = split_1.split(":")[split_1
        .split(":")
        .length - 1];
    String Filename = split_1.replaceAll(":", "-");
    String split_2 = Filename.split(FileVersion)[0];
    String Url =
        "${lib["url"]}${PackageName.replaceAll(".", "/")}/${split_2.substring(
        0, split_2.length - 1)}/${FileVersion}/${Filename}";

    Result["Filename"] = "${Filename}.jar";
    Result["Url"] = "${Url}.jar";
    // Result["Sha1Hash"] = "${Url}.sha1";
    return Result;
  }

  static Future<String> apiRequest(String url, Map jsonMap) async {
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    request.add(utf8.encode(json.encode(jsonMap)));
    HttpClientResponse response = await request.close();
    late var reply = '';
    reply = await response.transform(utf8.decoder).join();
    httpClient.close();
    return reply;
  }

  static String pathSeparator(src) {
    return src.replaceAll("/", Platform.pathSeparator);
  }

  static Future<bool> OpenJavaSelectScreen(BuildContext context,
      JavaVersion) async {
    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return false;
    }
    List JavaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (JavaFileList.any((element) => element == file.name)) {
      Config().Change("java_path_${JavaVersion}", file.path);
      return true;
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("尚未偵測到 Java"),
              content: Text("這個檔案不是 java 或 javaw。"),
              actions: <Widget>[
                TextButton(
                  child: Text(i18n.Format("gui.confirm")),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
      return false;
    }
  }

  static String DuplicateNameHandler(String Name) {
    return Name + "(${i18n.Format("gui.copy")})";;
  }

  static int murmurhash2(String str, int seed) {
    var l = str.length,
        h = seed ^ l,
        i = 0,
        k;

    while (l >= 4) {
      k =
      ((str.codeUnitAt(i) & 0xff)) |
      ((str.codeUnitAt(++i) & 0xff) << 8) |
      ((str.codeUnitAt(++i) & 0xff) << 16) |
      ((str.codeUnitAt(++i) & 0xff) << 24);

      k = (((k & 0xffff) * 0x5bd1e995) +
          ((((k >> 16) * 0x5bd1e995) & 0xffff) << 16));
      k ^= k >> 24;
      k = (((k & 0xffff) * 0x5bd1e995) +
          ((((k >> 16) * 0x5bd1e995) & 0xffff) << 16));

      h = (((h & 0xffff) * 0x5bd1e995) +
          ((((h >> 16) * 0x5bd1e995) & 0xffff) << 16)) ^ k;

      l -= 4;
      ++i;
    }

    switch (l) {
      case 3:
        h ^= (str.codeUnitAt(i + 2) & 0xff) << 16;
        continue len2;
      len2:
      case 2:
        h ^= (str.codeUnitAt(i + 1) & 0xff) << 8;
        continue len1;
      len1:
      case 1:
        h ^= (str.codeUnitAt(i) & 0xff);
        h = (((h & 0xffff) * 0x5bd1e995) +
            ((((h >> 16) * 0x5bd1e995) & 0xffff) << 16));
    }

    h ^= h >> 13;
    h = (((h & 0xffff) * 0x5bd1e995) +
        ((((h >> 16) * 0x5bd1e995) & 0xffff) << 16));
    h ^= h >> 15;

    return h >> 0;
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Config.dart';
import 'i18n.dart';

class utility {
  static OpenFileManager(Dir) async {
    if (Dir is Directory) {
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
    String FileVersion = split_1.split(":")[split_1.split(":").length - 1];
    String Filename = split_1.replaceAll(":", "-");
    String split_2 = Filename.split(FileVersion)[0];
    String Url =
        "${lib["url"]}${PackageName.replaceAll(".", "/")}/${split_2.substring(0, split_2.length - 1)}/${FileVersion}/${Filename}";

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

  static Future<bool> OpenJavaSelectScreen(
      BuildContext context, JavaVersion) async {
    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return false;
    }
    List JavaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (JavaFileList.any((element) => element == file.name)) {
      Config.Change("java_path_${JavaVersion}", file.path);
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
    return Name + "(${i18n.Format("gui.copy")})";
    ;
  }

  static int murmurhash2(File file) {
    /*
    murmurhash2 雜湊值計算
    由 https://raw.githubusercontent.com/HughBone/fabrilous-updater/main/src/main/java/com/hughbone/fabrilousupdater/util/Hash.java 轉換成Dart。
    */

    final int m = 0x5bd1e995;
    final int r = 24;
    int k = 0x0;
    int seed = 1;
    int shift = 0x0;

    int FileLength = file.lengthSync();

    Uint8List byteFile = file.readAsBytesSync();

    int length = 0;
    int b;
    for (int i = 0; i < FileLength; i++) {
      b = byteFile[i];
      if (b == 0x9 || b == 0xa || b == 0xd || b == 0x20) {
        continue;
      }
      length += 1;
    }
    int h = (seed ^ length);
    for (int i = 0; i < FileLength; i++) {
      b = byteFile[i];
      if (b == 0x9 || b == 0xa || b == 0xd || b == 0x20) {
        continue;
      }
      if (b > 255) {
        while (b > 255) {
          b -= 255;
        }
      }
      k = k | (b << shift);
      shift = shift + 0x8;
      if (shift == 0x20) {
        h = 0x00000000FFFFFFFF & h;
        k = k * m;
        k = 0x00000000FFFFFFFF & k;
        k = k ^ (k >> r);
        k = 0x00000000FFFFFFFF & k;
        k = k * m;
        k = 0x00000000FFFFFFFF & k;
        h = h * m;
        h = 0x00000000FFFFFFFF & h;
        h = h ^ k;
        h = 0x00000000FFFFFFFF & h;
        k = 0x0;
        shift = 0x0;
      }
    }

    if (shift > 0) {
      h = h ^ k;
      h = 0x00000000FFFFFFFF & h;
      h = h * m;
      h = 0x00000000FFFFFFFF & h;
    }

    h = h ^ (h >> 13);
    h = 0x00000000FFFFFFFF & h;
    h = h * m;
    h = 0x00000000FFFFFFFF & h;
    h = h ^ (h >> 15);
    h = 0x00000000FFFFFFFF & h;

    return h;
  }

  static List<String> split(String string, String separator, {int max = 0}) {
    List<String> result = [];

    if (separator.isEmpty) {
      result.add(string);
      return result;
    }

    while (true) {
      var index = string.indexOf(separator, 0);
      if (index == -1 || (max > 0 && result.length >= max)) {
        result.add(string);
        break;
      }

      result.add(string.substring(0, index));
      string = string.substring(index + separator.length);
    }

    return result;
  }

  static bool containsIgnoreCase(String a, String b) {
    return a.toLowerCase().contains(b.toLowerCase());
  }

  static String formatDuration(Duration duration) {
    String i18nHourse = i18n.Format('gui.time.hourse');
    String i18nMinutes = i18n.Format('gui.time.minutes');
    String i18nSeconds = i18n.Format('gui.time.seconds');

    int Hourse = duration.inHours;
    int Minutes = duration.inMinutes.remainder(60);
    int Seconds = duration.inSeconds.remainder(60);

    return("$Hourse $i18nHourse $Minutes $i18nMinutes $Seconds $i18nSeconds");
  }
}

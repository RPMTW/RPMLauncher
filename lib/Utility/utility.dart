import 'dart:convert';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Config.dart';
import 'i18n.dart';

class utility {
  static OpenFileManager(File) async {
    if (File.runtimeType == Directory) {
      CreateFolderOptimization(File);
    }
    if (Platform.isLinux) {
      await Process.run("xdg-open", [File.path]);
    } else if (Platform.isWindows) {
      await Process.run("start", [File.path], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run("open", [File.path]);
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

  static Future<void> OpenJavaSelectScreen(
      BuildContext context, JavaVersion) async {
    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return;
    }
    List JavaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (JavaFileList.any((element) => element == file.name)) {
      Config().Change("java_path_${JavaVersion}", file.path);
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
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static String getSeparator() {
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

  static Future<List> OpenJavaSelectScreen(BuildContext context) async {
    final file = await FileSelectorPlatform.instance.openFile(
        acceptedTypeGroups: [XTypeGroup(label: 'Java執行檔 (javaw/java)')]);
    if (file == null) {
      return [false, null];
    }
    List JavaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (JavaFileList.any((element) => element == file.name)) {
      return [true, file.path];
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
      return [false, null];
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
    String i18nHourse = i18n.Format('gui.time.hours');
    String i18nMinutes = i18n.Format('gui.time.minutes');
    String i18nSeconds = i18n.Format('gui.time.seconds');

    int Hourse = duration.inHours;
    int Minutes = duration.inMinutes.remainder(60);
    int Seconds = duration.inSeconds.remainder(60);

    return ("$Hourse $i18nHourse $Minutes $i18nMinutes $Seconds $i18nSeconds");
  }

  static List<void Function(String)> onData = [
    (data) {
      stdout.write(data);
    }
  ];

  static bool isSurrounded(String str, String prefix, String suffix) {
    return str.startsWith(prefix) && str.endsWith(suffix);
  }

  static String? getJarMainClass(File file) {
    String? MainClass;
    final Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    for (final file in archive) {
      if (file.isFile && file.name.startsWith("META-INF/MANIFEST.MF")) {
        final data = file.content as List<int>;
        String Manifest = Utf8Decoder(allowMalformed: true).convert(data);
        MainClass = parseJarManifest(Manifest)["Main-Class"];
      }
    }
    return MainClass;
  }

  static Map parseJarManifest(Manifest) {
    Map parsed = {};
    for (var i in Manifest.split("\n")) {
      List<String> lineData = i.split(":");
      String? data_ = lineData[0];
      if (data_.isNotEmpty) {
        parsed[data_] = i.replaceFirst(data_, "").replaceFirst(":", "");
      }
    }
    return parsed;
  }

  static Future<void> copyDirectory(
      Directory source, Directory destination) async {
    await source.list(recursive: false).forEach((FileSystemEntity entity) {
      if (entity is Directory) {
        var newDirectory =
            Directory(join(destination.absolute.path, basename(entity.path)));
        newDirectory.createSync(recursive: true);
        copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        entity.copySync(join(destination.path, basename(entity.path)));
      }
    });
  }

  static Future<void> OpenUrl(String url) async {
    if (await canLaunch(url)) {
      launch(url);
    } else {
      print("Can't open the url $url");
    }
  }

  static Future<bool> ValidateAccount(Map Account) async {
    if (Account['Type'] == account.Microsoft) {
      return await MSAccountHandler.Validate(Account["AccessToken"]);
    } else if (Account['Type'] == account.Mojang) {
      return await MojangHandler.Validate(Account["AccessToken"]);
    }
  }
}

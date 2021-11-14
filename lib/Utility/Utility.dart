import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Widget/DownloadJava.dart';
import 'package:rpmlauncher/main.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:system_info/system_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Config.dart';
import 'I18n.dart';

class Uttily {
  static openFileManager(FileSystemEntity fse) async {
    if (fse is Directory) {
      createFolderOptimization(fse);
    }

    if (Platform.isMacOS) {
      Process.run("open", [fse.absolute.path]);
    } else {
      openUri(Uri.decodeFull(fse.uri.toString()));
    }
  }

  static createFolderOptimization(Directory dir) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
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

  static Future<Map> parseLibMaven(lib) async {
    Map result = {};
    String packageName = lib["name"].toString().split(":")[0];
    String split_1 = lib["name"].toString().split("$packageName:").join("");
    String fileVersion = split_1.split(":")[split_1.split(":").length - 1];
    String filename = split_1.replaceAll(":", "-");
    String split_2 = filename.split(fileVersion)[0];
    String _path =
        "${packageName.replaceAll(".", "/")}/${split_2.substring(0, split_2.length - 1)}/$fileVersion/$filename";
    String url = "${lib["url"]}$_path.jar";

    result["Filename"] = "$filename.jar";
    result["Url"] = url;
    result["Sha1Hash"] = (await Dio().get(url + ".sha1")).data.toString();
    result['Path'] = "$_path.jar";
    return result;
  }

  static Future<String> apiRequest(String url, Map jsonMap) async {
    HttpClient httpClient = HttpClient();
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

  static Future<List> openJavaSelectScreen(BuildContext context) async {
    final file = await FileSelectorPlatform.instance.openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: I18n.format('launcher.java.install.manual.file'))
        ]);
    if (file == null) {
      return [false, null];
    }
    List javaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (javaFileList.any((element) => element == file.name)) {
      return [true, file.path];
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: I18nText("launcher.java.install.manual.file.error.title"),
              content:
                  I18nText("auncher.java.install.manual.file.error.message"),
              actions: [
                TextButton(
                  child: Text(I18n.format("gui.confirm")),
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

  static String duplicateNameHandler(String sourceName) {
    return sourceName + "(${I18n.format("gui.copy")})";
  }

  static int murmurhash2(File file) {
    /*
    murmurhash2 雜湊值計算
    由 https://raw.githubusercontent.com/HughBone/fabrilous-updater/main/src/main/java/com/hughbone/fabrilousupdater/util/Hash.java 移植到 Dart。
    */

    const int m = 0x5bd1e995;
    const int r = 24;
    int k = 0x0;
    int seed = 1;
    int shift = 0x0;

    int fileLength = file.lengthSync();

    Uint8List byteFile = file.readAsBytesSync();

    int length = 0;
    int b;
    for (int i = 0; i < fileLength; i++) {
      b = byteFile[i];
      if (b == 0x9 || b == 0xa || b == 0xd || b == 0x20) {
        continue;
      }
      length += 1;
    }
    int h = (seed ^ length);
    for (int i = 0; i < fileLength; i++) {
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
    String i18nHourse = I18n.format('gui.time.hours');
    String i18nMinutes = I18n.format('gui.time.minutes');
    String i18nSeconds = I18n.format('gui.time.seconds');

    int hourse = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return ("$hourse $i18nHourse $minutes $i18nMinutes $seconds $i18nSeconds");
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
    String? mainClass;
    final Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    for (final file in archive) {
      if (file.isFile && file.name.startsWith("META-INF/MANIFEST.MF")) {
        final data = file.content as List<int>;
        String manifest = Utf8Decoder(allowMalformed: true).convert(data);
        mainClass = parseJarManifest(manifest)["Main-Class"];
      }
    }
    return mainClass;
  }

  static Map parseJarManifest(manifest) {
    Map parsed = {};
    for (var i in manifest.split("\n")) {
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

  static Future<void> openUri(String uri) async {
    if (Platform.isLinux) {
      xdgOpen(uri);
    } else {
      if (await canLaunch(uri)) {
        launch(uri);
      } else {
        logger.send("Can't open the url $uri");
      }
    }
  }

  static Future<bool> validateAccount(Account account) async {
    if (!Config.getValue('validate_account')) return true;
    if (account.type == AccountType.microsoft) {
      return await MSAccountHandler.validate(account.accessToken);
    } else {
      return await MojangHandler.validate(account.accessToken);
    }
  }

  static Future<MinecraftMeta> getVanillaVersionMeta(String versionID) async {
    List<MCVersion> versionList = (await MCVersionManifest.vanilla()).versions;
    return versionList.firstWhere((version) => version.id == versionID).meta;
  }

  static void javaCheck({Function? notHasJava, Function? hasJava}) {
    List<int> javaVersions = [8, 16];
    List<int> needVersions = [];
    for (var version in javaVersions) {
      String javaPath = Config.getValue("java_path_$version");

      /// 假設Java路徑無效或者不存在
      if (javaPath == "" || !File(javaPath).existsSync()) {
        needVersions.add(version);
      }
    }

    if (needVersions.isNotEmpty) {
      if (notHasJava == null) {
        showDialog(
            context: navigator.context,
            builder: (context) => DownloadJava(javaVersions: needVersions));
      } else {
        notHasJava.call();
      }
    } else {
      hasJava?.call();
    }
  }

  static Future<void> openNewWindow(RouteSettings routeSettings) async {
    if (kReleaseMode) {
      try {
        bool runInShell = false;
        if (Platform.isLinux || Platform.isMacOS) {
          await chmod(LauncherInfo.getExecutingFile().path);
        }

        if (Platform.isMacOS) {
          runInShell = true;
        }

        await Process.run(LauncherInfo.getExecutingFile().path,
            ['--route', routeSettings.name.toString(), '--newWindow', 'true'],
            runInShell: runInShell);
      } catch (e, stackTrace) {
        logger.error(ErrorType.unknown, e, stackTrace: stackTrace);
      }
    } else {
      navigator.pushNamed(routeSettings.name!);
    }
  }

  static Future<int> getTotalPhysicalMemory() async {
    if (Platform.isWindows) {
      return await RPMLauncherPlugin.getTotalPhysicalMemory();
    } else {
      int _ = ((SysInfo.getTotalPhysicalMemory()) / 1024 ~/ 1024);
      _ = _ - _ % 1024;
      return _;
    }
  }

  static bool accessFilePermissions(FileSystemEntity fileSystemEntity) {
    try {
      File _ = File(join(fileSystemEntity.path, 'test'));
      _.createSync(recursive: true);
      _.deleteSync(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Version parseMCComparableVersion(String sourceVersion) {
    Version _comparableVersion;
    try {
      _comparableVersion = Version.parse(sourceVersion);
    } catch (e) {
      String? _preVersion() {
        int pos = sourceVersion.indexOf("-pre");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Pre-release ");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Pre-Release ");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Release Candidate ");
        if (pos >= 0) return sourceVersion.substring(0, pos);
      }

      String? _str = _preVersion();
      if (_str != null) {
        try {
          return Version.parse(_str);
        } catch (e) {
          return Version.parse("$_str.0");
        }
      }

      /// 例如 21w44a
      RegExp _ = RegExp(r'(?:(?<yy>\d\d)w(?<ww>\d\d)[a-z])');
      if (_.hasMatch(sourceVersion)) {
        RegExpMatch match = _.allMatches(sourceVersion).toList().first;

        String praseRelease(int year, int week) {
          if (year == 21 && week >= 37) {
            return "1.18.0";
          } else if (year == 21 && (week >= 3 && week <= 20)) {
            return "1.17.0";
          } else if (year == 20 && week >= 6) {
            return "1.16.0";
          } else if (year == 19 && week >= 34) {
            return "1.15.2";
          } else if (year == 18 && week >= 43 || year == 19 && week <= 14) {
            return "1.14.0";
          } else if (year == 18 && week >= 30 && week <= 33) {
            return "1.13.1";
          } else if (year == 17 && week >= 43 || year == 18 && week <= 22) {
            return "1.13.0";
          } else if (year == 17 && week == 31) {
            return "1.12.1";
          } else if (year == 17 && week >= 6 && week <= 18) {
            return "1.12.0";
          } else if (year == 16 && week == 50) {
            return "1.11.1";
          } else if (year == 16 && week >= 32 && week <= 44) {
            return "1.11.0";
          } else if (year == 16 && week >= 20 && week <= 21) {
            return "1.10.0";
          } else if (year == 16 && week >= 14 && week <= 15) {
            return "1.9.3";
          } else if (year == 15 && week >= 31 || year == 16 && week <= 7) {
            return "1.9.0";
          } else if (year == 14 && week >= 2 && week <= 34) {
            return "1.8.0";
          } else if (year == 13 && week >= 47 && week <= 49) {
            return "1.7.4";
          } else if (year == 13 && week >= 36 && week <= 43) {
            return "1.7.2";
          } else if (year == 13 && week >= 16 && week <= 26) {
            return "1.6.0";
          } else if (year == 13 && week >= 11 && week <= 12) {
            return "1.5.1";
          } else if (year == 13 && week >= 1 && week <= 10) {
            return "1.5.0";
          } else if (year == 12 && week >= 49 && week <= 50) {
            return "1.4.6";
          } else if (year == 12 && week >= 32 && week <= 42) {
            return "1.4.2";
          } else if (year == 12 && week >= 15 && week <= 30) {
            return "1.3.1";
          } else if (year == 12 && week >= 3 && week <= 8) {
            return "1.2.1";
          } else if (year == 11 && week >= 47 || year == 12 && week <= 1) {
            return "1.1.0";
          } else {
            return "1.17.1";
          }
        }

        int year = int.parse(match.group(1).toString()); //ex: 21
        int week = int.parse(match.group(2).toString()); //ex: 44

        _comparableVersion = Version.parse(praseRelease(year, week));
      } else {
        _comparableVersion = Version.none;
      }
    }

    return _comparableVersion;
  }
}

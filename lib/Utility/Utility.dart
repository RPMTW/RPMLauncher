import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio_http/dio_http.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Account.dart';
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
    } else if (Platform.isLinux) {
      xdgOpen(fse.absolute.path);
    } else {
      openUrl(Uri.decodeFull(fse.uri.toString()));
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
        acceptedTypeGroups: [XTypeGroup(label: 'Java執行檔 (javaw/java)')]);
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
              title: const Text("尚未偵測到 Java"),
              content: Text("這個檔案不是 java 或 javaw。"),
              actions: <Widget>[
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

  static Future<void> openUrl(String url) async {
    if (await canLaunch(url)) {
      launch(url);
    } else {
      logger.send("Can't open the url $url");
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

  static Future<Map> vanillaVersions() async {
    Response response =
        await Dio().get("$mojangMetaAPI/version_manifest_v2.json");
    Map data = response.data;
    return data;
  }

  static Future<Map> getVanillaVersionMeta(String versionID) async {
    List versionList = (await vanillaVersions())['versions'];
    Map versionMeta =
        versionList.firstWhere((version) => version['id'] == versionID);
    Response response = await Dio().get(versionMeta['url']);
    Map data = response.data;
    return data;
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
        if (Platform.isLinux || Platform.isLinux) {
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

  static bool validInstanceName(String name) {
    if (name == "") return false;
    if (InstanceRepository.instanceConfigFile(name).existsSync()) return false;
    RegExp reg = RegExp(':|<|>|\\*|\\?|/');
    return !reg.hasMatch(name);
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
}

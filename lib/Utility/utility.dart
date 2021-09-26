import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:archive/archive.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Widget/DownloadJava.dart';
import 'package:rpmlauncher/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Config.dart';
import 'i18n.dart';

class utility {
  static OpenFileManager(FileSystemEntity FSE) async {
    if (FSE is Directory) {
      CreateFolderOptimization(FSE);
    }

    if (Platform.isMacOS) {
      Process.run("open", [FSE.absolute.path]);
    } else {
      OpenUrl(Uri.decodeFull(FSE.uri.toString()));
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
                  child: Text(i18n.format("gui.confirm")),
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
    return Name + "(${i18n.format("gui.copy")})";
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
    String i18nHourse = i18n.format('gui.time.hours');
    String i18nMinutes = i18n.format('gui.time.minutes');
    String i18nSeconds = i18n.format('gui.time.seconds');

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
      logger.send("Can't open the url $url");
    }
  }

  static Future<bool> ValidateAccount(Map Account) async {
    if (Account['Type'] == account.Microsoft) {
      return await MSAccountHandler.Validate(Account["AccessToken"]);
    } else {
      return await MojangHandler.Validate(Account["AccessToken"]);
    }
  }

  static Future<Map> VanillaVersions() async {
    final url = Uri.parse("${MojangMetaAPI}/version_manifest_v2.json");
    Response response = await get(url);
    Map data = jsonDecode(response.body);
    return data;
  }

  static Future<Map> getVanillaVersionMeta(String VersionID) async {
    List Versions = (await VanillaVersions())['versions'];
    Map Version = Versions.firstWhere((version) => version['id'] == VersionID);
    final url = Uri.parse(Version['url']);
    Response response = await get(url);
    Map data = jsonDecode(response.body);
    return data;
  }

  static void JavaCheck({Function? notHasJava, Function? hasJava}) {
    List<int> JavaVersions = [8, 16];
    List<int> needVersions = [];
    for (var version in JavaVersions) {
      String JavaPath = Config.getValue("java_path_${version}");

      /// 假設Java路徑無效或者不存在
      if (JavaPath == "" || !File(JavaPath).existsSync()) {
        needVersions.add(version);
      }
    }

    if (needVersions.isNotEmpty) {
      if (notHasJava == null) {
        showDialog(
            context: navigator.context,
            builder: (context) => DownloadJava(JavaVersions: needVersions));
      } else {
        notHasJava.call();
      }
    } else {
      return hasJava?.call();
    }
  }

  static Future<void> OpenNewWindow(RouteSettings routeSettings) async {
    if (kReleaseMode) {
      try {
        if (Platform.isLinux) {
          await Process.run("chmod", [
            "+x",
            LauncherInfo.getExecutingFile().path.replaceFirst('/', '')
          ]);
        }
        ProcessResult PR = await Process.run(
            LauncherInfo.getExecutingFile().path.replaceFirst('/', ''), [
          '--route',
          "${routeSettings.name}",
          '--arguments',
          json.encode({'NewWindow': true})
        ]);

        PR.stdout.transform(utf8.decoder).listen((data) {
          utility.onData.forEach((event) {
            logger.send("OepnNewWindows Task\n$data");
          });
        });
      } catch (e) {
        logger.send(e);
      }
    } else {
      navigator.pushNamed(routeSettings.name!, arguments: {'NewWindow': false});
      // Process.run('flutter', [
      //   'run',
      //   LauncherInfo.getRuningFile().absolute.path,
      //   "--dart-define",
      //   "build_id=${LauncherInfo.getVersionCode()}",
      //   "--dart-define",
      //   "version_type=${Updater.toStringFromVersionType(LauncherInfo.getVersionType())}",
      //   "--dart-define",
      //   "version=${LauncherInfo.getVersion()}",
      //   '--route',
      //   "/instance/1.17.1/edit"
      // ]);
    }
  }

  static bool ValidDirName(String name) {
    RegExp reg = RegExp(
        r'^((?:[a-zA-Z]:)|(?:\\{2}\w[-\w]*)\$?)\\(?!\.)((?:(?![\\/:*?<>"|])(?![.\x20](?:\\|$))[\x20-\x7E])+\\(?!\.))*((?:(?:(?![\\/:*?<>"|])(?![ .]$)[\x20-\x7E])+)\.((?:(?![\\/:*?<>"|])(?![ .]$)[\x20-\x7E]){2,15}))?$');
    return reg.hasMatch(name);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/account/microsoft_account_handler.dart';
import 'package:rpmlauncher/account/mojang_account_handler.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/model/IO/Properties.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/Process.dart';
import 'package:rpmlauncher/widget/dialog/DownloadJava.dart';
import 'package:rpmlauncher/util/Data.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Config.dart';
import 'I18n.dart';

class Util {
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

  static String? getMinecraftFormatOS() {
    if (Platform.isWindows) {
      return "windows";
    } else if (Platform.isLinux) {
      return "linux";
    } else if (Platform.isMacOS) {
      return "osx";
    }
    return null;
  }

  static String getLibrarySeparator() {
    if (Platform.isLinux || Platform.isMacOS) {
      return ":";
    } else {
      return ";";
    }
  }

  static Map parseLibMaven(Map lib, {String? baseUrl}) {
    baseUrl ??= lib['url'];
    String name = lib["name"];
    Map result = {};
    String packageName = name.split(":")[0];
    String split_1 = name.split("$packageName:").join("");
    String fileVersion = split_1.split(":")[split_1.split(":").length - 1];
    String filename = split_1.replaceAll(":", "-");
    String split_2 = filename.split(fileVersion)[0];
    String path = "";
    if (packageName.contains(".")) {
      path += "${packageName.replaceAll(".", "/")}/";
    }

    if (split_2.length > 1) {
      path += "${split_2.substring(0, split_2.length - 1)}/";
    }

    path += "$fileVersion/$filename";

    String url = "$baseUrl$path.jar";

    result["Filename"] = "$filename.jar";
    result["Url"] = url;

    result['Path'] = "$path.jar";
    return result;
  }

  static String pathSeparator(src) {
    return src.replaceAll("/", Platform.pathSeparator);
  }

  static Future<List> openJavaSelectScreen(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        dialogTitle: I18n.format('launcher.java.install.manual.file'));
    if (result == null) {
      return [false, null];
    }
    PlatformFile file = result.files.single;
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
    String i18nDay = I18n.format('gui.time.day');
    String i18nHours = I18n.format('gui.time.hours');
    String i18nMinutes = I18n.format('gui.time.minutes');
    String i18nSeconds = I18n.format('gui.time.seconds');

    return RPMTWUtil.formatDuration(duration,
        i18nDay: i18nDay,
        i18nHour: i18nHours,
        i18nMinute: i18nMinutes,
        i18nSecond: i18nSeconds);
  }

  static bool isSurrounded(String str, String prefix, String suffix) {
    return str.startsWith(prefix) && str.endsWith(suffix);
  }

  static String? getJarMainClass(File file) {
    String? mainClass;
    final Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    for (final file in archive) {
      if (file.isFile && file.name.startsWith("META-INF/MANIFEST.MF")) {
        final data = file.content as List<int>;
        String manifest = const Utf8Decoder(allowMalformed: true).convert(data);
        mainClass = Properties.decode(manifest, splitChar: ":")["Main-Class"];
      }
    }
    return mainClass;
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
    if (kTestMode) return;

    if (Platform.isLinux) {
      xdgOpen(uri);
    } else {
      await launch(uri).catchError((e) {
        logger.error(ErrorType.io, "Can't open the url $uri");
      });
    }
  }

  static Future<bool> validateAccount(Account account) async {
    if (!Config.getValue('validate_account')) return true;
    if (account.type == AccountType.microsoft) {
      bool isValid = await MSAccountHandler.validate(account.accessToken);

      if (!isValid) {
        // 憑證已過期，開始嘗試自動更新憑證
        Credentials credentials = await account.credentials!.refresh(
          identifier: microsoftClientID,
        );
        List<MicrosoftAccountStatus> statusList =
            await MSAccountHandler.authorization(credentials).toList();

        try {
          MicrosoftAccountStatus status = statusList
              .firstWhere((s) => s == MicrosoftAccountStatus.successful);

          /// 儲存更新後的憑證資訊
          status.getAccountData()!.save();

          /// 更新成功因此回傳 true
          return true;
        } catch (e) {
          /// 如果自動更新失敗則回傳 false
          return false;
        }
      }

      return isValid;
    } else {
      return await MojangHandler.validate(account.accessToken);
    }
  }

  static Future<MinecraftMeta> getVanillaVersionMeta(String versionID) async {
    List<MCVersion> versionList =
        (await MCVersionManifest.getVanilla()).versions;
    return versionList.firstWhere((version) => version.id == versionID).meta;
  }

  static List<int> javaCheck(List<int> allJavaVersions) {
    List<int> needVersions = [];
    for (var version in allJavaVersions) {
      String? javaPath = Config.getValue("java_path_$version");

      /// 假設Java路徑無效或者不存在
      if (javaPath == null || javaPath == "" || !File(javaPath).existsSync()) {
        needVersions.add(version);
      }
    }

    return needVersions;
  }

  static void javaCheckDialog(
      {Function? notHasJava, Function? hasJava, List<int>? allJavaVersions}) {
    allJavaVersions ??= [8, 16, 17];
    List<int> needVersions = javaCheck(allJavaVersions);
    if (needVersions.isNotEmpty) {
      if (notHasJava == null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          showDialog(
              context: navigator.context,
              builder: (context) => DownloadJava(
                    javaVersions: needVersions,
                    onDownloaded: hasJava,
                  ));
        });
      } else {
        notHasJava.call();
      }
    } else {
      hasJava?.call();
    }
  }

  static Future<WindowController> openNewWindow(String route,
      {String? title}) async {
    final WindowController window =
        await DesktopMultiWindow.createWindow(json.encode({"route": route}));
    if (title != null) {
      await window.setTitle(title);
    }
    final Size size = WidgetsBinding.instance.window.physicalSize;
    window.setFrame(const Offset(0, 0) & size);

    await window.center();
    await window.show();

    return window;
  }

  static Future<void> closeWindow() async =>
      await LauncherInfo.windowController.close();

  static bool accessFilePermissions(FileSystemEntity fileSystemEntity) {
    try {
      File file = File(join(fileSystemEntity.path, 'test'));
      file.createSync(recursive: true);
      file.deleteSync(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Version parseMCComparableVersion(String sourceVersion) {
    Version comparableVersion;
    try {
      try {
        comparableVersion = Version.parse(sourceVersion);
      } catch (e) {
        comparableVersion = Version.parse("$sourceVersion.0");
      }
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
        return null;
      }

      String? str = _preVersion();
      if (str != null) {
        try {
          return Version.parse(str);
        } catch (e) {
          return Version.parse("$str.0");
        }
      }

      /// Handling snapshot version (e.g. 21w44a)
      RegExp snapshotPattern = RegExp(r'(?:(?<yy>\d\d)w(?<ww>\d\d)[a-z])');
      if (snapshotPattern.hasMatch(sourceVersion)) {
        RegExpMatch match =
            snapshotPattern.allMatches(sourceVersion).toList().first;

        String praseRelease(int year, int week) {
          if (year == 22 && week >= 3) {
            return "1.18.2";
          } else if (year == 21 && week >= 37) {
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
            return "1.18.0";
          }
        }

        int year = int.parse(match.group(1).toString()); //ex: 21
        int week = int.parse(match.group(2).toString()); //ex: 44

        comparableVersion = Version.parse(praseRelease(year, week));
      } else {
        comparableVersion = Version.none;
      }
    }

    return comparableVersion;
  }

  static Future<bool> hasNetWork() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  static bool exceptionFilter(Object exception, StackTrace stackTrace) {
    if (exception is FileSystemException &&
        (exception.message == "writeFrom failed" ||
            exception.message == "Directory listing failed")) return true;
    if (exception.toString() == "Null check operator used on a null value" &&
        stackTrace.toString().contains('State.setState')) {
      return true;
    }
    return false;
  }

  static Stream<FileSystemEvent> fileWatcher(File file) {
    String fileName = basename(file.path);
    Directory dir = file.parent;
    Stream<FileSystemEvent> stream = Stream.multi((p0) {
      dir.watch().listen((e) {
        if (e is FileSystemModifyEvent) {
          if (e.path.endsWith(fileName)) {
            p0.add(e);
          }
        } else {
          if (e.path.endsWith(fileName)) {
            p0.add(e);
          }
        }
      });
    });

    return stream;
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat.yMMMMEEEEd(Platform.localeName)
        .add_jms()
        .format(dateTime);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:io' as io show exit;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/account/microsoft_account_handler.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/model/io/properties.dart';
import 'package:rpmlauncher/model/account/account.dart';
import 'package:rpmlauncher/util/process.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config/config.dart';
import '../i18n/i18n.dart';

class Util {
  static String? getMinecraftFormatOS() {
    if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isMacOS) {
      return 'osx';
    }
    return null;
  }

  static String getLibrarySeparator() {
    if (Platform.isLinux || Platform.isMacOS) {
      return ':';
    } else {
      return ';';
    }
  }

  static String pathSeparator(src) {
    return src.replaceAll('/', Platform.pathSeparator);
  }

  static Future<List> openJavaSelectScreen(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: I18n.format('launcher.java.install.manual.file'));
    if (result == null) {
      return [false, null];
    }

    PlatformFile file = result.files.single;
    List javaFileList = ['java', 'javaw', 'java.exe', 'javaw.exe'];
    if (javaFileList.any((element) => element == file.name)) {
      return [true, file.path];
    } else {
      if (context.mounted) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title:
                    I18nText('launcher.java.install.manual.file.error.title'),
                content:
                    I18nText('auncher.java.install.manual.file.error.message'),
                actions: [
                  TextButton(
                    child: Text(I18n.format('gui.confirm')),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      }

      return [false, null];
    }
  }

  static int getMurmur2Hash(File file) {
    /*
    murmurhash2 雜湊值計算
    由 https://github.com/HughBone/fabrilous-updater/blob/5e8341951087cd4a622939bef552445b52b12f9b/src/main/java/com/hughbone/fabrilousupdater/util/Hash.java 移植到 Dart。
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
      if (file.isFile && file.name.startsWith('META-INF/MANIFEST.MF')) {
        final data = file.content as List<int>;
        String manifest = const Utf8Decoder(allowMalformed: true).convert(data);
        mainClass = Properties.decode(manifest, splitChar: ':')['Main-Class'];
      }
    }
    return mainClass;
  }


  static Future<void> openUri(String url) async {
    if (kTestMode) return;

    if (Platform.isLinux) {
      xdgOpen(url);
    } else {
      await launchUrlString(url).catchError((e) {
        logger.error(ErrorType.io, 'Can\'t open the url $url');
        return true;
      });
    }
  }

  static Future<bool> validateAccount(Account account) async {
    if (!launcherConfig.checkAccountValidity) return true;
    if (account.type == AccountType.microsoft) {
      bool isValid = await MSAccountHandler.validate(account.accessToken);

      if (!isValid) {
        // The token is expired, so we need to refresh it.
        try {
          final Credentials credentials = await account.credentials!.refresh(
            identifier: LauncherInfo.microsoftClientID,
          );
          final List<MicrosoftAccountStatus> statusList =
              await MSAccountHandler.authorization(credentials).toList();

          return statusList.any((e) => e == MicrosoftAccountStatus.successful);
        } catch (e) {
          logger.error(
              ErrorType.authorization, 'Can\'t refresh the credentials');
          return false;
        }
      }

      return isValid;
    } else {
      return false;
    }
  }

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
        (exception.message == 'writeFrom failed' ||
            exception.message == 'Directory listing failed')) return true;
    if (exception.toString() == 'Null check operator used on a null value' &&
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

  static Future<void> exit([int code = 0]) async {
    if (kTestMode) {
      // no-op
    } else {
      await DataBox.close();
      io.exit(code);
    }
  }

  static String getCPUArchitecture() {
    if (Platform.isWindows) {
      return Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
    } else {
      final ProcessResult result = Process.runSync('uname', ['-m']);
      return result.stdout.toString().replaceAll('\n', '');
    }
  }
}

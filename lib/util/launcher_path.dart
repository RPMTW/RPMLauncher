import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

late Directory _root;

class LauncherPath {
  static Directory? _customDataHome;
  static Directory? _customDefaultDataHome;

  static Directory get defaultDataHome {
    if (_customDefaultDataHome != null) {
      return _customDefaultDataHome!;
    }

    return _root;
  }

  static Directory get currentConfigHome => defaultDataHome;
  static Directory get currentDataHome {
    if (_customDataHome != null) {
      return _customDataHome!;
    }

    try {
      return launcherConfig.launcherDataDir;
    } catch (e) {
      init();
      return Directory.current;
    }
  }

  static Future<void> init() async {
    late String base;

    try {
      final String userHome = absolute(Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '');
      final String flatpakPath = '$userHome/.var/app/ga.rpmtw.rpmlauncher';

      if (Platform.isLinux && LauncherInfo.isFlatpakApp) {
        base = flatpakPath;
      } else {
        /// Handle path of old versions
        final Directory oldPath;
        if (Platform.isLinux) {
          if (LauncherInfo.isFlatpakApp) {
            oldPath = Directory(flatpakPath);
          } else {
            oldPath = Directory(userHome);
          }
        } else {
          oldPath = await getApplicationDocumentsDirectory();
        }

        if (Directory(join(oldPath.path, 'RPMLauncher')).existsSync()) {
          base = oldPath.path;
        } else {
          base = (await getApplicationSupportDirectory()).absolute.path;
        }
      }

      if (!base.isEnglish && Platform.isLinux) {
        /// 非 英文/數字 符號
        if (Util.accessFilePermissions(Directory.systemTemp)) {
          base = Directory.systemTemp.absolute.path;
        }
      }
    } catch (e) {
      base = Directory.current.absolute.path;
    }
    if (kTestMode) {
      _root = Directory(join(base, 'RPMLauncher', 'test'));
      if (_root.existsSync()) {
        await _root.delete(recursive: true);
      }
    } else {
      _root = Directory(join(base, 'RPMLauncher', 'data'));
    }

    IOUtil.createDirectory(_root);
    IOUtil.createDirectory(currentDataHome);
  }

  static void setCustomDataHome(Directory home, Directory defaultHome) {
    _customDataHome = home;
    _customDefaultDataHome = defaultHome;
  }
}

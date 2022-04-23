import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

late Directory _root;

class LauncherPath {
  static Directory? _customDataHome;

  static Directory get defaultDataHome => _root;
  static Directory get currentConfigHome => defaultDataHome;
  static Directory get currentDataHome {
    if (_customDataHome != null) {
      return _customDataHome!;
    }

    try {
      return Directory(Config.getValue('data_home'));
    } catch (e) {
      init();
      return Directory.current;
    }
  }

  static Future<void> init() async {
    late String base;

    try {
      if (Platform.isLinux) {
        String home = absolute(Platform.environment['HOME']!);
        if (LauncherInfo.isFlatpakApp &&
            Util.accessFilePermissions(Directory(home))) {
          base = "$home/.var/app/ga.rpmtw.rpmlauncher";
        } else {
          base = home;
        }
      } else {
        base = (await getApplicationDocumentsDirectory()).absolute.path;
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
      _root = Directory(join(base, "RPMLauncher", "test"));
      if (_root.existsSync()) {
        await _root.delete(recursive: true);
      }
    } else {
      _root = Directory(join(base, "RPMLauncher", "data"));
    }

    Util.createFolderOptimization(_root);
    GameRepository.init(_root);
    Util.createFolderOptimization(currentDataHome);
  }

  static void setCustomDataHome(Directory home) {
    _customDataHome = home;
  }
}

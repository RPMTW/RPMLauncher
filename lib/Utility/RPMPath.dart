import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

late Directory _root;

class RPMPath {
  static Directory get defaultDataHome => _root;
  static Directory get currentConfigHome => defaultDataHome;
  static Directory get currentDataHome {
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
            Uttily.accessFilePermissions(Directory(home))) {
          base = "$home/.var/app/ga.rpmtw.rpmlauncher";
        } else {
          base = home;
        }
      } else {
        base = (await getApplicationDocumentsDirectory()).absolute.path;
      }

      if (!base.isEnglish && Platform.isLinux) {
        /// 非 英文/數字 符號
        if (Uttily.accessFilePermissions(Directory.systemTemp)) {
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

    Uttily.createFolderOptimization(_root);
    GameRepository.init(_root);
    Uttily.createFolderOptimization(currentDataHome);
  }
}

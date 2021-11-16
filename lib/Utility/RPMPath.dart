import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

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
    late String _base;
    try {
      if (Platform.isLinux) {
        String home = absolute(Platform.environment['HOME']!);
        if (LauncherInfo.isFlatpakApp) {
          _base = "$home/.var/app/ga.rpmtw.rpmlauncher";
        } else {
          _base = home;
        }
      } else {
        _base = (await getApplicationDocumentsDirectory()).absolute.path;
      }

      if (!_base.isASCII) {
        /// 非 英文/數字 符號
        if (Uttily.accessFilePermissions(Directory.systemTemp)) {
          _base = Directory.systemTemp.absolute.path;
        }
      }
    } catch (e) {
      _base = Directory.current.absolute.path;
    }
    _root = Directory(join(_base, "RPMLauncher", "data"));

    Uttily.createFolderOptimization(_root);
    GameRepository.init(_root);
    Uttily.createFolderOptimization(currentDataHome);
  }
}

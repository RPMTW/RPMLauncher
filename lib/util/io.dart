import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/util/util.dart';

class IOUtil {
  static Future<void> openFileManager(FileSystemEntity fse) async {
    if (fse is Directory) {
      createFolderOptimization(fse);
    }

    if (Platform.isMacOS) {
      await Process.run('open', [fse.absolute.path]);
    } else {
      await Util.openUri(Uri.decodeFull(fse.uri.toString()));
    }
  }

  static void createFolderOptimization(Directory dir) {
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  static String replaceFolderName(String name) {
    /// Windows: \/:*?"<>|
    /// Unix: /
    final regexp = RegExp(r'[\\/:*?"<>|]');

    if (name.isEmpty) {
      return '_';
    }

    return name.replaceAll(regexp, '_').trimRight();
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
}

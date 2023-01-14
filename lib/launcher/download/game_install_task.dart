import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/collection/collection.dart';
import 'package:rpmlauncher/launcher/collection/component.dart';
import 'package:rpmlauncher/launcher/download/assets_download_task.dart';
import 'package:rpmlauncher/launcher/download/library_download_task.dart';
import 'package:rpmlauncher/launcher/download/version_meta_download_task.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/model/game/version/mc_version_meta.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/util/io_util.dart';

class GameInstallTask extends Task<void> {
  final String displayName;
  final GameLoader loader;
  final MCVersion version;

  GameInstallTask(
      {required this.displayName, required this.loader, required this.version});

  @override
  Future<void> execute() async {
    setMessage('正在安裝遊戲中...');
    final directory = GameRepository.getCollectionsDirectory();
    final name =
        _handleDuplicateName(IOUtil.replaceFolderName(displayName), directory);
    final gameDirectory = Directory(join(directory.path, name));

    IOUtil.createDirectory(gameDirectory);

    final components = [Component.minecraft(version.id)];
    final collection = Collection(
        name: name, displayName: displayName, components: components);

    final configFile = File(join(gameDirectory.path, 'collection.json'));
    await configFile.writeAsString(json.encode(collection.toJson()));

    final MCVersionMeta meta = preSubTasks[0].result;

    addPostSubTask(LibraryDownloadTask(meta.libraries));
    addPostSubTask(GameAssetsDownloadTask(meta.assetIndex));
    return;
  }

  @override
  Future<void> preExecute() async {
    addPreSubTask(VersionMetaDownloadTask(version));
  }

  /// Handle duplicate names of the collection directory.
  String _handleDuplicateName(String name, Directory directory) {
    final dir = Directory(join(directory.path, name));
    if (dir.existsSync()) {
      final regexp = RegExp(r'\(\d+\)');
      final String newName;

      // Replace the number in the parentheses with the next number
      // Example: 'name (1)' -> 'name (2)'
      if (name.contains(regexp) && name.endsWith(')')) {
        newName = name.replaceAllMapped(regexp,
            (match) => '(${int.parse(match.group(0)!.substring(1, 2)) + 1})');
      } else {
        newName = '$name (1)';
      }

      return _handleDuplicateName(newName, directory);
    } else {
      return name;
    }
  }
}

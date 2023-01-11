import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/model/game/version/mc_version_meta.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class DownloadVersionMetaTask extends Task<MCVersionMeta> {
  final MCVersion version;

  DownloadVersionMetaTask(this.version);

  @override
  Future<MCVersionMeta> execute() async {
    final metaDirectory = GameRepository.getMetaDirectory();
    final filePath =
        join(metaDirectory.path, 'net.minecraft', '${version.id}.json');
    final file = File(filePath);

    // Check if the file exists and the hash is correct.
    if (file.existsSync() && _checkHash(file)) {
      return MCVersionMeta.fromJson(json.decode(file.readAsStringSync()));
    }

    await httpClient.download(
      version.url,
      filePath,
      onReceiveProgress: (count, total) {
        if (total != -1) {
          setProgress(count / total);
        }
      },
    );

    return MCVersionMeta.fromJson(json.decode(file.readAsStringSync()));
  }

  bool _checkHash(File file) {
    return sha1.convert(file.readAsBytesSync()).toString() == version.sha1;
  }

  @override
  Future<void> postExecute() async {}

  @override
  Future<void> preExecute() async {}
}

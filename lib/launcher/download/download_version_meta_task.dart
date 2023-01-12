import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/model/game/version/mc_version_meta.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/util/io_util.dart';
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
    if (IOUtil.isCachedFileSha1(file, version.sha1)) {
      return MCVersionMeta.fromJson(json.decode(file.readAsStringSync()));
    }

    // Download the file of version meta.
    await httpClient.download(
      version.url,
      filePath,
      onReceiveProgress: (count, total) => setProgressByCount(count, total),
    );

    return MCVersionMeta.fromJson(json.decode(file.readAsStringSync()));
  }

  @override
  Future<void> postExecute() async {}

  @override
  Future<void> preExecute() async {}
}

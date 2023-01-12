import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/game/version/mc_version_meta.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class GameAssetsDownloadTask extends Task<void> {
  final MCVersionMeta meta;

  GameAssetsDownloadTask(this.meta);

  @override
  Future<void> execute() async {
    setMessage('正在下載遊戲資源中...');
    final assetsDirectory = GameRepository.getAssetsDirectory();
    final assetIndex = meta.assetIndex;

    final indexFilePath =
        join(assetsDirectory.path, 'indexes', '${assetIndex.id}.json');
    final indexFile = File(indexFilePath);

    if (!IOUtil.isCachedFileSha1(indexFile, assetIndex.sha1)) {
      await httpClient.download(
        assetIndex.url,
        indexFilePath,
        onReceiveProgress: (count, total) => setProgressByCount(count, total),
      );
    }

    return;
  }

  @override
  Future<void> preExecute() async {}

  @override
  Future<void> postExecute() async {}
}

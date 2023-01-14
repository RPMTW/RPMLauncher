import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/game/assets/asset_object.dart';
import 'package:rpmlauncher/model/game/assets/assets_index.dart';
import 'package:rpmlauncher/model/game/version/mc_version_asset_index.dart';
import 'package:rpmlauncher/task/isolate_task.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class AssetsDownloadTask extends IsolateTask<void> {
  final MCVersionAssetIndex assetIndex;

  AssetsDownloadTask(this.assetIndex);

  @override
  String get name => 'assets_download_task';

  @override
  Future<void> execute() async {
    setMessage('正在下載遊戲資源中...');
    final assetsDirectory = GameRepository.getAssetsDirectory();

    final indexFilePath =
        join(assetsDirectory.path, 'indexes', '${assetIndex.id}.json');
    final indexFile = File(indexFilePath);

    if (!IOUtil.isCachedFileSha1(indexFile, assetIndex.sha1)) {
      await httpClient.download(assetIndex.url, indexFilePath);
    }

    final index =
        AssetsIndex.fromJson(json.decode(indexFile.readAsStringSync()));
    final futures = <Future>[];
    final total = index.objects.length;
    int current = 0;

    for (final object in index.objects.values) {
      if (isCanceled) return;
      futures.add(_download(object).whenComplete(() {
        current++;
        setProgressByCount(current, total);
      }));
    }

    await Future.wait(futures);
    return;
  }

  Future<void> _download(AssetObject object) async {
    final file = File(object.getFilePath());
    if (!IOUtil.isCachedFileSha1(file, object.hash)) {
      await httpClient.download(object.getDownloadUrl(), object.getFilePath());
    }
  }
}

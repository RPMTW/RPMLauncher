import 'package:rpmlauncher/model/game/version/detail_mc_version_manifest.dart';
import 'package:rpmlauncher/task/task.dart';

class GameAssetsDownloadTask extends Task<void> {
  final DetailMcVersionManifest manifest;

  GameAssetsDownloadTask(this.manifest);

  @override
  Future<void> execute() async {
    setMessage('正在下載遊戲資源中...');

    return;
  }

  @override
  Future<void> preExecute() async {}

  @override
  Future<void> postExecute() async {}
}

import 'package:rpmlauncher/model/game/version/mc_version_meta.dart';
import 'package:rpmlauncher/task/task.dart';

class GameAssetsDownloadTask extends Task<void> {
  final MCVersionMeta meta;

  GameAssetsDownloadTask(this.meta);

  @override
  Future<void> execute() async {
    setMessage('正在下載遊戲資源中...');

    print(meta.assets);

    return;
  }

  @override
  Future<void> preExecute() async {}

  @override
  Future<void> postExecute() async {}
}

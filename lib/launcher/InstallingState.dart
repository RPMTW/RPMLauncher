import 'package:rpmlauncher/model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/util/I18n.dart';

InstallingState installingState = InstallingState();

class InstallingState {
  DownloadInfos downloadInfos = DownloadInfos.empty();
  String nowEvent = I18n.format('version.list.downloading.ready');
  bool finish = false;
}

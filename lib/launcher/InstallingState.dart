import 'package:rpmlauncher/model/IO/download_info.dart';
import 'package:rpmlauncher/util/i18n.dart';

InstallingState installingState = InstallingState();

class InstallingState {
  DownloadInfos downloadInfos = DownloadInfos.empty();
  String nowEvent = I18n.format('version.list.downloading.ready');
  bool finish = false;
}

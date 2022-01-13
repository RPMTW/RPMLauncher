import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

InstallingState installingState = InstallingState();

class InstallingState {
  DownloadInfos downloadInfos = DownloadInfos.empty();
  String nowEvent = I18n.format('version.list.downloading.ready');
  bool finish = false;
}

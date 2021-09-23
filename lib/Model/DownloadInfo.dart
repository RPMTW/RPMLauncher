import 'dart:collection';

import 'dart:io';

import 'package:dio_http/dio_http.dart';
import 'package:rpmlauncher/Launcher/CheckData.dart';

class DownloadInfos extends ListBase<DownloadInfo> {
  /// 一個下載資訊列表的類別
  /// [infos] 下載資訊列表
  /// [progress] 下載進度，如果尚未開始下載則為 0.0
  /// [downloading] 是否正在下載檔案中

  List<DownloadInfo> infos = [];
  double progress = double.nan;
  bool downloading = false;

  DownloadInfos(this.infos);

  factory DownloadInfos.none() {
    return DownloadInfos([]);
  }

  /// 下載所有檔案
  Future<void> downloadAll(
      {Function(double progress)? onReceiveProgress}) async {
    downloading = true;

    int count = infos.length;
    int done = 0;

    void onDone() {
      done++;
      progress = done / count;
      onReceiveProgress?.call(progress);
    }

    for (DownloadInfo info in infos) {
      if (info.hashCheck && info.file.existsSync()) {
        if (info.sh1Hash is String) {
          if (CheckData.CheckSha1Sync(
              info.file, info.sh1Hash!)) {
            onDone();
            continue;
          }
        }
      }
      await info.download();
      onDone();
    }
    downloading = false;
  }

  @override
  int get length => infos.length;

  @override
  DownloadInfo operator [](int index) {
    return infos[index];
  }

  @override
  void operator []=(int index, DownloadInfo value) {
    infos[index] = value;
  }

  @override
  set length(int newLength) {
    infos.length = newLength;
  }
}

class DownloadInfo {
  /// [hashCheck] 是否檢查雜湊值檔案完整性
  /// [sh1Hash] Sh1 雜湊值，用於檢測檔案完整性
  /// [mo5Hash] Sh1 雜湊值，用於檢測檔案完整性

  final String? title;
  final String savePath;
  final String downloadUrl;
  final String? description;
  final bool hashCheck;
  final String? sh1Hash;

  Uri get downloadUri => Uri.parse(downloadUrl);
  File get file => File(savePath);
  double progress = double.nan;

  /// 下載檔案
  Future<void> download() async {
    await Dio().download(downloadUrl, savePath,
        onReceiveProgress: (int count, int total) {
      progress = count / total;
    });
  }

  DownloadInfo(this.downloadUrl,
      {this.title,
      this.hashCheck = false,
      this.sh1Hash,
      this.description,
      required this.savePath});
}

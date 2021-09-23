import 'dart:collection';

import 'dart:io';

import 'package:dio_http/dio_http.dart';

class DownloadInfos extends IterableBase<DownloadInfo> {
  /// 一個下載資訊列表的類別
  /// [infos] 下載資訊列表
  /// [progress] 下載進度，如果尚未開始下載則為 0.0
  /// [downloading] 是否正在下載檔案中

  List<DownloadInfo> infos = [];
  double progress = double.nan;
  bool downloading = false;

  DownloadInfos(this.infos);

  /// 下載所有檔案
  Future<void> downloadAll() async {
    downloading = true;

    int count = infos.length;
    int done = 0;

    for (DownloadInfo DownloadInfo in infos) {
      await DownloadInfo.download();
      done++;
      progress = done / count;
    }
    downloading = false;
  }

  @override
  Iterator<DownloadInfo> get iterator => infos.iterator;
}

class DownloadInfo {
  final String title;
  final double length;
  final String? savePath;
  final String downloadUrl;
  final String? description;
  Uri get downloadUri => Uri.parse(downloadUrl);
  File get file => File(savePath!);
  double progress = double.nan;

  /// 下載檔案
  Future<void> download() async {
    if (savePath != null) {
      await Dio().download(downloadUrl, savePath,
          onReceiveProgress: (int count, int total) {
        progress = count / total;
      });
    } else {
      throw Exception('Download failed because the save path was null');
    }
  }

  DownloadInfo(this.downloadUrl,
      {required this.title,
      required this.length,
      this.description,
      this.savePath});
}

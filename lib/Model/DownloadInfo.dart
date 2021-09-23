import 'dart:collection';

import 'dart:io';

import 'package:dio_http/dio_http.dart';

class DownloadInfos extends IterableBase<DownloadInfo> {
  List<DownloadInfo> infos = [];

  DownloadInfos(this.infos);

  /// 下載所有檔案
  /// [max] 同時最大下載數量
  Future<void> downloadAll({int max = 1}) async {
    for (DownloadInfo DownloadInfo in infos) {
      await DownloadInfo.download();
    }
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
  double progress = 0;

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

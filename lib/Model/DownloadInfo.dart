import 'dart:collection';

import 'dart:io';

import 'package:dio_http/dio_http.dart';
import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';

class DownloadInfos extends IterableBase<DownloadInfo> {
  /// 一個下載資訊列表的類別
  /// [infos] 下載資訊列表
  /// [progress] 下載進度，如果尚未開始下載則為 0.0
  /// [downloading] 是否正在下載檔案中

  List<DownloadInfo> infos;
  double progress = 0.0;
  bool downloading = false;

  DownloadInfos(this.infos);

  factory DownloadInfos.none() {
    return DownloadInfos([]);
  }

  /// 下載所有檔案
  Future<void> downloadAll(
      {Function(double progress)? onReceiveProgress, int max = 10}) async {
    downloading = true;

    int count = infos.length;
    int done = 0;

    await _downloadAsync(
        onDone: () {
          done++;
          progress = done / count;
          onReceiveProgress?.call(progress);
        },
        max: max);
    infos.clear();

    downloading = false;
  }

  /// 異步下載檔案
  /// [max] 最多同時執行幾個異步函數
  Future<void> _downloadAsync({Function? onDone, int max = 10}) async {
    int _count = (infos.length / max).ceil();
    int _ = 0;
    List<Future<void>> futureList = [];

    for (int i = 0; i <= max; i++) {
      futureList.add(Future.forEach(
          infos.sublist(
              i == 0
                  ? 0
                  : (max == i ? (infos.length - _count) : (i - 1) * _count),
              max == i ? infos.length : i * _count), (DownloadInfo info) async {
        await info.download().whenComplete(() => onDone?.call());
      }));
    }

    await Future.wait(futureList);
  }

  void add(DownloadInfo value) {
    return infos.add(value);
  }

  @override
  Iterator<DownloadInfo> get iterator => infos.iterator;
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
  final Function? onDownloaded;

  Uri get downloadUri => Uri.parse(downloadUrl);
  File get file => File(savePath);
  double progress = double.nan;

  /// 下載檔案
  Future<void> download({Function(double progress)? onDownloading}) async {
    if (description != null) {
      nowEvent = description!;
    }
    if (hashCheck &&
        file.existsSync() &&
        sh1Hash != null &&
        CheckData.checkSha1Sync(file, sh1Hash!)) return;
    await Dio().download(downloadUrl, savePath,
        onReceiveProgress: (int count, int total) {
      progress = count / total;
      onDownloading?.call(progress);
    });
    onDownloaded?.call();
  }

  DownloadInfo(this.downloadUrl,
      {this.title,
      this.hashCheck = false,
      this.sh1Hash,
      this.onDownloaded,
      this.description,
      required this.savePath});
}

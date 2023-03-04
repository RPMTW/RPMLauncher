import 'dart:async';
import 'dart:io';

import 'package:rpmlauncher/task/async_sub_task.dart';
import 'package:rpmlauncher/task/task_size.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class FetchTask extends AsyncSubTask<void> {
  final String url;
  final String path;
  final String? hash;
  final int? fileSize;

  FetchTask({required this.url, required this.path, this.hash, this.fileSize});

  int _oldTotalDownloaded = 0;
  int _newTotalDownloaded = 0;
  int downloadSpeed = 0;

  void _init() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (isFinished) {
        timer.cancel();
        // If the file size is very small, the download speed will be 0, so we set it to its size.
        if (downloadSpeed == 0 &&
            fileSize != null &&
            _newTotalDownloaded != 0) {
          downloadSpeed = fileSize! ~/ 2;
          await Future.delayed(const Duration(milliseconds: 500));
          downloadSpeed = fileSize! ~/ 2;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        downloadSpeed = 0;
        return;
      }

      downloadSpeed = _newTotalDownloaded - _oldTotalDownloaded;
      _oldTotalDownloaded = _newTotalDownloaded;
    });
  }

  void _setFetchProgress(int downloaded, int total) {
    if (total != -1) {
      setProgress(downloaded / (fileSize ?? total));
    }

    _newTotalDownloaded = downloaded;
  }

  @override
  Future<void> execute() async {
    _init();
    final file = File(path);

    if (hash != null && IOUtil.isCachedFileSha1(file, hash!)) {
      setProgress(1);
      return;
    }

    await httpClient.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        _setFetchProgress(received, total);
      },
    );
  }

  @override
  String get name => 'fetch_task ($url)';

  @override
  TaskSize get size => TaskSize.tiny;
}

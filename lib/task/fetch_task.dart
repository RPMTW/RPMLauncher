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

  int receivedBytes = 0;

  void _init() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isFinished) {
        timer.cancel();
        return;
      }

      receivedBytes = 0;
      final tasks = preSubTasks + postSubTasks;
      for (final task in tasks.whereType<FetchTask>()) {
        receivedBytes += task.receivedBytes;
      }
    });
  }

  void _setFetchProgress(int received, int total) {
    if (total != -1) {
      setProgress(received / (fileSize ?? total));
    }

    receivedBytes += received;
  }

  @override
  Future<void> execute() async {
    _init();
    final file = File(path);

    if (hash != null && IOUtil.isCachedFileSha1(file, hash!)) {
      if (fileSize != null) {
        _setFetchProgress(fileSize!, fileSize!);
      } else {
        setProgress(1);
      }
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
  TaskSize get size => TaskSize.small;
}

import 'dart:async';
import 'dart:isolate';

import 'package:rpmlauncher/model/io/isolate_option.dart';
import 'package:rpmlauncher/task/basic_task.dart';
import 'package:rpmlauncher/task/fetch_task.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/task/task_status.dart';

/// A task running in the [Isolate].
abstract class IsolateTask<R> extends BasicTask<R> {
  @override
  Future<R?> run() {
    return _runInIsolate();
  }

  Future<R?> _runInIsolate() async {
    final updatePort = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();
    final Completer<R?> completer = Completer();

    updatePort.listen((task) {
      if (task is Task) {
        print(task);

        message = task.message;
        status = task.status;
        progress = task.progress;
        error = task.error;
        result = task.result;
        preSubTasks = task.preSubTasks;
        postSubTasks = task.postSubTasks;
      }

      // if (task is FetchTask) {
      //   receivedBytes = task.receivedBytes;
      // }

      notifyListeners();
    });

    exitPort.listen((_) {
      completer.complete(result);
      setStatus(TaskStatus.success);
    });

    errorPort.listen((_) {
      final String error = _[0];
      final StackTrace? stackTrace =
          _[1] != null ? StackTrace.fromString(_[1]) : null;

      completer.completeError(error, stackTrace);
      setStatus(TaskStatus.failed);
    });

    final option = IsolateOption.create(this, ports: [updatePort.sendPort]);
    final isolate =
        await Isolate.spawn((IsolateOption<IsolateTask<R>> option) async {
      option.init();
      final task = option.argument;

      task.addListener(() {
        option.sendData(task);
      });

      await task._superRun();
    }, option, debugName: '${name}_$id');

    isolate.addOnExitListener(exitPort.sendPort);
    isolate.addErrorListener(errorPort.sendPort);

    return await completer.future;
  }

  Future<void> _superRun() {
    return super.run();
  }
}

import 'dart:async';
import 'dart:isolate';

import 'package:rpmlauncher/model/io/isolate_option.dart';
import 'package:rpmlauncher/task/basic_task.dart';

/// A task running in the [Isolate].
abstract class IsolateTask<R> extends BasicTask<R> {
  @override
  Future<R?> run() {
    _runInIsolate();
    return super.run();
  }

  Future<R?> _runInIsolate() async {
    final updatePort = ReceivePort();
    final exitPort = ReceivePort();
    final Completer<R?> completer = Completer();

    updatePort.listen((data) {
      if (data is List) {
        message = data[0];
        status = data[1];
        progress = data[2];
        error = data[3];
        result = data[4];

        notify();
      }
    });

    exitPort.listen((_) {
      completer.complete(result);
    });

    final option = IsolateOption.create(null, ports: [updatePort.sendPort]);
    final isolate = await Isolate.spawn((IsolateOption option) async {
      option.init();

      onNotify.listen((task) {
        option.sendData([
          task.message,
          task.status,
          task.progress,
          task.error,
          task.result
        ]);
      });

      await Future.delayed(const Duration(seconds: 1));

      await super.run();
      Isolate.exit();
    }, option, debugName: '${name}_$id');

    isolate.addOnExitListener(exitPort.sendPort);

    return await completer.future;
  }
}

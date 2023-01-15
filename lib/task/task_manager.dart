import 'dart:async';

import 'package:rpmlauncher/task/task.dart';

final taskManager = TaskManager();

class TaskManager {
  /// Tasks managed by this class.
  final List<BasicTask> _tasks = [];

  double networkSpeed = 0.0;

  /// Submit a task to run.
  Future<void> submit(BasicTask task) async {
    _tasks.add(task);
    task.onNotify.listen((task) {
      if (task.isCanceled) {
        _tasks.remove(task);
      }
    });
    await task.run();
  }

  /// Remove a task.
  void remove(BasicTask task) {
    task.cancel();
    _tasks.remove(task);
  }

  List<BasicTask> getAll() {
    return _tasks;
  }
}

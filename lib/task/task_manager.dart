import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/task/fetch_task.dart';
import 'package:rpmlauncher/task/task.dart';

final taskManager = TaskManager()..init();

class TaskManager extends ChangeNotifier {
  /// Tasks managed by this class.
  static final List<Task> _tasks = [];

  int downloadSpeed = 0;

  void init() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final tasks = _tasks.expand((e) => e.allSubTask).whereType<FetchTask>();
      downloadSpeed = tasks.fold(0, (p, e) => p + e.downloadSpeed);

      notifyListeners();
    });
  }

  /// Submit a task to run.
  Future<void> submit(Task task) async {
    _tasks.add(task);
    task.addListener(() {
      if (task.isCanceled) {
        _tasks.remove(task);
      }
    });
    await task.run();
    notifyListeners();
  }

  /// Remove a task.
  void remove(Task task) {
    task.cancel();
    _tasks.remove(task);
  }

  List<Task> getAll() {
    return _tasks;
  }
}

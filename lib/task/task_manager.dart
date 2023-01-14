import 'dart:async';

import 'package:rpmlauncher/task/task.dart';

final taskManager = TaskManager();

class TaskManager {
  final List<Task> _tasks = [];
  late final StreamController<List<Task>> _updateBroadcast =
      StreamController<List<Task>>.broadcast(
    onListen: () => _update(),
  );

  double networkSpeed = 0.0;

  Future<void> add(Task task) async {
    _tasks.add(task);
    task.listen((task) {
      if (task.isCanceled) {
        _tasks.remove(task);
      }
    });
    await task.run();
  }

  void remove(Task task) {
    _tasks.remove(task);
    _update();
  }

  void _update() {
    _updateBroadcast.add(_tasks);
  }

  Stream<List<Task>> get onUpdate => _updateBroadcast.stream;
}

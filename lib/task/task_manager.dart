import 'package:rpmlauncher/task/task.dart';

final taskManager = TaskManager();

class TaskManager {
  final List<Task> _tasks = [];
  double networkSpeed = 0.0;

  void add(Task task) {
    _tasks.add(task);
    task.listen((task) {
      if (task.isCanceled) {
        _tasks.remove(task);
      }
    });
    task.run();
  }

  List<Task> getAll() {
    return _tasks;
  }
}

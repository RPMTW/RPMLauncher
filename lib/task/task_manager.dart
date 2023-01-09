import 'package:rpmlauncher/task/task.dart';

final downloadTaskManager = DownloadTaskManager();

class DownloadTaskManager {
  final List<Task> _tasks = [];

  void addTask(Task task) {
    _tasks.add(task);
  }
}

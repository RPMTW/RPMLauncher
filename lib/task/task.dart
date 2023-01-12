import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rpmlauncher/task/task_status.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:uuid/uuid.dart';

/// Disposable task abstract class.
/// You can extends this class to create a task.
abstract class Task<R> extends Equatable {
  // Private variables
  TaskStatus _status = TaskStatus.ready;
  double? _progress = 0.0;
  final List<Task> _postSubTasks = [];
  final List<Task> _preSubTasks = [];
  String? _message;
  late StreamController<Task<R>> _streamController;
  Object? _error;
  R? _result;

  final String id = const Uuid().v4();

  /// Default status is [TaskStatus.ready].
  /// Also see [TaskStatus].
  TaskStatus get status => _status;

  /// The value of progress should be between 0.0 and 1.0.
  /// If the value is null, it means the task is not running or **unable to calculate** the progress.
  double? get progress => _progress;

  /// Calculate the total progress of this task and all sub-tasks.
  /// This task and all sub-tasks each take up 50% of the total progress.
  double get totalProgress {
    final thisProgress = progress ?? 0.0;
    if (_postSubTasks.isEmpty) {
      return thisProgress;
    }

    final subTasksProgress = _postSubTasks
            .map((task) => task.totalProgress)
            .reduce((value, element) => value + element) /
        _postSubTasks.length;

    return (thisProgress * 0.5 + subTasksProgress * 0.5).clamp(0.0, 1.0);
  }

  /// The list of sub-tasks should be executed **after** this task.
  /// If this task failed, it would not be executed.
  List<Task> get postSubTasks => _postSubTasks;

  /// The list of sub-tasks should be executed **before** this task.
  /// If the sub-tasks failed, this task would not be executed.
  List<Task> get preSubTasks => _preSubTasks;

  /// Represents the message of the current task execution stage.
  String? get message => _message;

  /// Will be null if the task is not failed.
  Object? get error => _error;

  R? get result => _result;

  /// Run the task and run all sub-tasks.
  ///
  /// The task will be executed in the following order:
  /// 1. [preExecute]
  /// 1.1. [preSubTasks]
  /// 2. [execute]
  /// 2.1. [postSubTasks] (if the task is successful)
  /// 3. [postExecute] (if the task is successful)
  Future<R?> run() async {
    _streamController = StreamController<Task<R>>.broadcast(
        onListen: () => _update(), onCancel: () => _streamController.close());
    _status = TaskStatus.running;

    try {
      await preExecute();
      if (status == TaskStatus.canceled) {
        await _streamController.close();
        return null;
      }

      await _runSubTasks(preSubTasks);
      _result = await execute();
      await _runSubTasks(postSubTasks);
      await postExecute();
      _status = TaskStatus.success;
    } catch (e, st) {
      _error = e;
      _status = TaskStatus.failed;
      logger.error(ErrorType.task, error, stackTrace: st);
    }

    setProgress(1.0);
    await _streamController.close();

    return _result;
  }

  void setStatus(TaskStatus status) {
    _status = status;
    _update();
  }

  void setProgress(double? progress) {
    if (progress != null && (progress < 0 || progress > 1.0)) {
      throw Exception('Progress should be between 0.0 and 1.0');
    }

    _progress = progress;
    _update();
  }

  void setProgressByCount(int count, int total) {
    if (total == -1) return;
    setProgress(count / total);
  }

  void addPostSubTask(Task task) {
    _postSubTasks.add(task);
  }

  void addPreSubTask(Task task) {
    _preSubTasks.add(task);
  }

  void setMessage(String? message) {
    _message = message;
    _update();
  }

  /// Listen to the status, progress and message of this task.
  void listen(void Function(Task<R> task) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) async {
    _streamController.stream.listen((task) {
      onData.call(task);
    }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void cancel() {
    _status = TaskStatus.canceled;
    _update();
  }

  /// Run before the task is executed.
  Future<void> preExecute();

  /// The method to execute the task should return a result.
  Future<R> execute();

  /// Run after the task is executed successfully.
  Future<void> postExecute();

  void _update() {
    _streamController.add(this);
  }

  Future<void> _runSubTasks(List<Task> subTasks) async {
    for (final task in subTasks) {
      if (status == TaskStatus.canceled) {
        await _streamController.close();
        break;
      }

      final future = task.run();
      task.listen((task) {
        setStatus(task.status);
        setMessage(task.message);
      });
      await future;
    }
  }

  @override
  List<Object?> get props => [id];
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rpmlauncher/task/abstract_task.dart';
import 'package:rpmlauncher/task/async_task.dart';
import 'package:rpmlauncher/task/task_status.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:meta/meta.dart';

/// You can extends this class to create a task.
abstract class BasicTask<R> extends Equatable implements Task<R> {
  // Private variables
  TaskStatus _status = TaskStatus.ready;
  double? _progress = 0.0;
  final List<Task> _postSubTasks = [];
  final List<Task> _preSubTasks = [];
  String? _message;
  late StreamController<BasicTask<R>> _notifyController;
  Object? _error;
  R? _result;

  @protected
  set status(value) => _status = value;

  @protected
  set message(value) => _message = value;

  @protected
  set progress(value) => _progress = value;

  @protected
  set error(value) => _error = value;

  @protected
  set result(value) => _result = value;

  BasicTask() {
    _notifyController = StreamController<BasicTask<R>>.broadcast(
        onListen: () => notify(), onCancel: () => _closeStream());
  }

  @override
  final String id = const Uuid().v4();

  @override
  TaskStatus get status => _status;

  @override
  bool get isCanceled => _status == TaskStatus.canceled;

  @override
  double? get progress => _progress;

  @override
  double get totalProgress {
    final thisProgress = progress ?? 1.0;
    if (_postSubTasks.isEmpty) {
      return thisProgress;
    }

    final allSubTasks = preSubTasks + postSubTasks;

    final subTasksProgress = allSubTasks
            .map((task) => task.totalProgress)
            .reduce((value, element) => value + element) /
        allSubTasks.length;

    return (thisProgress * 0.5 + subTasksProgress * 0.5).clamp(0.0, 1.0);
  }

  @override
  List<Task> get postSubTasks => _postSubTasks;

  @override
  List<Task> get preSubTasks => _preSubTasks;

  @override
  String? get message => _message;

  @override
  Object? get error => _error;

  @override
  R? get result => _result;

  @override
  Future<R?> run() async {
    _status = TaskStatus.running;

    try {
      await preExecute();
      if (isCanceled) {
        await _closeStream();
        return null;
      }

      await runSubTasks(preSubTasks);
      _result = await execute();
      await runSubTasks(postSubTasks);
      await postExecute();
      _status = TaskStatus.success;
    } catch (e, st) {
      _error = e;
      _status = TaskStatus.failed;
      logger.error(ErrorType.task, error, stackTrace: st);
    }

    // setProgress(1.0);
    await _closeStream();

    return _result;
  }

  @override
  void setStatus(TaskStatus status) {
    _status = status;
    notify();
  }

  @override
  void setProgress(double? progress) {
    if (progress != null && (progress < 0 || progress > 1.0)) {
      throw Exception('Progress should be between 0.0 and 1.0');
    }

    _progress = progress;
    notify();
  }

  @override
  void setProgressByCount(int count, int total) {
    if (total == -1) return;
    setProgress(count / total);
  }

  @override
  void addPostSubTask(Task task) {
    _postSubTasks.add(task);
  }

  @override
  void addPreSubTask(Task task) {
    _preSubTasks.add(task);
  }

  @override
  void setMessage(String? message) {
    _message = message;
    notify();
  }

  @override
  Stream<Task<R>> get onNotify => _notifyController.stream;

  @override
  void cancel() {
    _status = TaskStatus.canceled;
    notify();
  }

  @override
  Future<void> preExecute() async {}

  @override
  Future<R> execute();

  @override
  Future<void> postExecute() async {}

  @protected
  void notify() {
    if (_notifyController.isClosed) return;
    _notifyController.add(this);
  }

  @protected
  Future<void> runSubTasks(List<Task> subTasks) async {
    final asyncTasks = subTasks.whereType<AsyncTask>().toList();
    final syncTasks = subTasks.where((e) => e is! AsyncTask).toList();

    if (asyncTasks.isNotEmpty) {
      await Future.wait(asyncTasks.map(_runSubTask));
    }

    for (final task in syncTasks) {
      await _runSubTask(task);
    }
  }

  Future<void> _runSubTask(Task task) async {
    if (isCanceled) {
      await _closeStream();
      return;
    }

    task.onNotify.listen((task) {
      if (task.message != null) {
        setMessage(task.message);
      }
    });
    await task.run();
  }

  Future<void> _closeStream() async {
    if (!_notifyController.isClosed) {
      await _notifyController.close();
    }
  }

  @override
  List<Object?> get props => [name, id];
}

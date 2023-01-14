import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rpmlauncher/task/abstract_task.dart';
import 'package:rpmlauncher/task/task_status.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:uuid/uuid.dart';

/// You can extends this class to create a task.
abstract class Task<R> extends Equatable implements ITask<R> {
  // Private variables
  TaskStatus _status = TaskStatus.ready;
  double? _progress = 0.0;
  final List<ITask> _postSubTasks = [];
  final List<ITask> _preSubTasks = [];
  String? _message;
  late StreamController<Task<R>> _streamController;
  Object? _error;
  R? _result;

  Task({this.async = false}) {
    _streamController = StreamController<Task<R>>.broadcast(
        onListen: () => _update(), onCancel: () => _closeStream());
  }

  @override
  final bool async;

  @override
  final String id = const Uuid().v4();

  @override
  TaskStatus get status => _status;

  bool get isCanceled => _status == TaskStatus.canceled;

  @override
  double? get progress => _progress;

  @override
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

  @override
  List<ITask> get postSubTasks => _postSubTasks;

  @override
  List<ITask> get preSubTasks => _preSubTasks;

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
    await _closeStream();

    return _result;
  }

  @override
  void setStatus(TaskStatus status) {
    _status = status;
    _update();
  }

  @override
  void setProgress(double? progress) {
    if (progress != null && (progress < 0 || progress > 1.0)) {
      throw Exception('Progress should be between 0.0 and 1.0');
    }

    _progress = progress;
    _update();
  }

  @override
  void setProgressByCount(int count, int total) {
    if (total == -1) return;
    setProgress(count / total);
  }

  @override
  void addPostSubTask(ITask task) {
    _postSubTasks.add(task);
  }

  @override
  void addPreSubTask(ITask task) {
    _preSubTasks.add(task);
  }

  @override
  void setMessage(String? message) {
    _message = message;
    _update();
  }

  @override
  void listen(void Function(Task<R> task) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) async {
    _streamController.stream.listen((task) {
      onData.call(task);
    }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  void cancel() {
    _status = TaskStatus.canceled;
    _update();
  }

  @override
  Future<void> preExecute() async {}

  @override
  Future<R> execute();

  @override
  Future<void> postExecute() async {}

  void _update() {
    _streamController.add(this);
  }

  Future<void> _runSubTasks(List<ITask> subTasks) async {
    Future<void> run(ITask task) async {
      if (isCanceled) {
        await _closeStream();
        return;
      }

      task.listen((task) {
        setStatus(task.status);
        setMessage(task.message);
      });
      await task.run();
    }

    final asyncTasks = subTasks.where((task) => task.async).toList();
    final syncTasks = subTasks.where((task) => !task.async).toList();

    await Future.wait(asyncTasks.map(run));
    for (final task in syncTasks) {
      await run(task);
    }
  }

  Future<void> _closeStream() async {
    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }

  @override
  List<Object?> get props => [id];
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:quiver/iterables.dart';
import 'package:rpmlauncher/task/fetch_task.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/task/async_sub_task.dart';
import 'package:rpmlauncher/task/task_size.dart';
import 'package:rpmlauncher/task/task_status.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:uuid/uuid.dart';

/// You can extends this class to create a task.
abstract class BasicTask<R> extends Equatable
    with ChangeNotifier
    implements Task<R> {
  // Private variables
  TaskStatus _status = TaskStatus.queued;
  double _progress = 0.0;
  List<Task> _postSubTasks = [];
  List<Task> _preSubTasks = [];
  String? _message;
  Object? _error;
  R? _result;

  @protected
  set status(value) => _status = value;

  @protected
  set message(value) => _message = value;

  @protected
  set progress(value) => _progress = value;

  @protected
  set preSubTasks(value) => _preSubTasks = value;

  @protected
  set postSubTasks(value) => _postSubTasks = value;

  @protected
  set error(value) => _error = value;

  @protected
  set result(value) => _result = value;

  BasicTask();

  factory BasicTask.function(FutureOr<R> Function() function,
      {required String name,
      required TaskSize size,
      List<Task> preSubTasks = const [],
      List<Task> postSubTasks = const []}) {
    return _FunctionTask<R>(
        function: function,
        name: name,
        size: size,
        preSubTasks: preSubTasks,
        postSubTasks: postSubTasks);
  }

  @override
  final String id = const Uuid().v4();

  @override
  TaskStatus get status => _status;

  @override
  bool get isCanceled => _status == TaskStatus.canceled;

  @override
  bool get isFinished =>
      _status == TaskStatus.success ||
      _status == TaskStatus.failed ||
      isCanceled;

  @override
  double get progress => _progress;

  @override
  double get totalProgress {
    final subTasks = allSubTask;

    if (subTasks.isEmpty) {
      return progress;
    }

    final totalProgress = subTasks
            .map((e) => e.totalProgress * e.size.weight)
            .reduce((value, element) => value + element) /
        subTasks
            .map((e) => e.size.weight)
            .reduce((value, element) => value + element);

    return totalProgress;
  }

  @override
  List<Task> get postSubTasks => _postSubTasks;

  @override
  List<Task> get preSubTasks => _preSubTasks;

  @override
  List<Task> get allSubTask {
    final tasks = <Task>[...preSubTasks, ...postSubTasks];

    if (tasks.isEmpty) {
      return [];
    } else {
      return tasks.expand((e) => e.preSubTasks + e.postSubTasks).toList();
    }
  }

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
        await dispose();
        return null;
      }

      await runSubTasks(preSubTasks);
      _result = await execute();
      await runSubTasks(postSubTasks);
      await postExecute();
      allSubTask.whereType<FetchTask>().forEach((e) => e.downloadSpeed = 0);
      _status = TaskStatus.success;
      setProgress(1.0);
    } catch (e, st) {
      _error = e;
      _status = TaskStatus.failed;
      logger.error(ErrorType.task, error, stackTrace: st);
    }

    await dispose();

    return _result;
  }

  @override
  @protected
  void setStatus(TaskStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  @protected
  void setProgress(double progress) {
    if (progress < 0 || progress > 1.0) {
      throw Exception('Progress should be between 0.0 and 1.0');
    }

    _progress = progress;
    notifyListeners();
  }

  @override
  @protected
  void addPostSubTask(Task task) {
    _postSubTasks.add(task);
  }

  @override
  @protected
  void addPreSubTask(Task task) {
    _preSubTasks.add(task);
  }

  @override
  @protected
  void setMessage(String? message) {
    _message = message;
    notifyListeners();
  }

  @override
  void cancel() {
    if (isFinished) return;
    _status = TaskStatus.canceled;
    notifyListeners();
  }

  @override
  @protected
  Future<void> preExecute() async {}

  @override
  @protected
  Future<R> execute();

  @override
  @protected
  Future<void> postExecute() async {}

  @protected
  Future<void> runSubTasks(List<Task> subTasks) async {
    final asyncTasks = subTasks.whereType<AsyncSubTask>();
    final syncTasks = subTasks.where((e) => e is! AsyncSubTask);

    if (asyncTasks.isNotEmpty) {
      /// Max 15 async tasks can run at the same time.
      final list = partition(asyncTasks, 15);

      for (final tasks in list) {
        await Future.wait(tasks.map(_runSubTask));
      }
    }

    for (final task in syncTasks) {
      await _runSubTask(task);
    }
  }

  Future<void> _runSubTask(Task task) async {
    if (isCanceled) {
      await dispose();
      return;
    }

    task.addListener(() {
      if (task.message != null) {
        setMessage(task.message);
      }
    });
    await task.run();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  List<Object?> get props =>
      [name, id, status, progress, message, error, result];
}

class _FunctionTask<R> extends BasicTask<R> {
  final FutureOr<R> Function() function;

  @override
  final String name;

  @override
  final TaskSize size;

  @override
  final List<Task> preSubTasks;

  @override
  final List<Task> postSubTasks;

  _FunctionTask(
      {required this.function,
      required this.name,
      required this.size,
      this.preSubTasks = const [],
      this.postSubTasks = const []});

  @override
  Future<R> execute() async => await function();
}

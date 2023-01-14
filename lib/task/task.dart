import 'dart:async';
import 'dart:isolate';

import 'package:equatable/equatable.dart';
import 'package:rpmlauncher/model/io/isolate_option.dart';
import 'package:rpmlauncher/task/abstract_task.dart';
import 'package:rpmlauncher/task/task_status.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:uuid/uuid.dart';

/// You can extends this class to create a task.
abstract class Task<R> extends Equatable implements ITask<R> {
  // Private variables
  TaskStatus _status = TaskStatus.ready;
  double? _progress;
  final List<ITask> _postSubTasks = [];
  final List<ITask> _preSubTasks = [];
  String? _message;
  late StreamController<Task<R>> _updateController;
  Object? _error;
  R? _result;

  Task({this.isolate = false, this.async = false}) {
    _updateController = StreamController<Task<R>>.broadcast(
        onListen: () => _update(), onCancel: () => _closeStream());
  }

  @override
  final bool isolate;

  @override
  final bool async;

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
    if (isolate) {
      final updatePort = ReceivePort();

      updatePort.listen((data) {
        if (data is List) {
          _message = data[0];
          _status = data[1];
          _progress = data[2];
          _error = data[3];
          _result = data[4];

          _update();
        }
      });

      return _runInIsolate(this, _run, updatePort.sendPort);
    } else {
      return _run();
    }
  }

  Future<R?> _run() async {
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

    // setProgress(1.0);
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

  Stream<Task<R>> get onUpdate => _updateController.stream;

  @override
  void listen(void Function(ITask task) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onUpdate.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
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
    if (_updateController.isClosed) return;
    _updateController.add(this);
  }

  Future<void> _runSubTasks(List<ITask> subTasks) async {
    Future<void> run(ITask task) async {
      if (isCanceled) {
        await _closeStream();
        return;
      }

      task.listen((task) {
        if (task.message != null) {
          setMessage(task.message);
        }
      });
      await task.run();
    }

    final asyncTasks = subTasks.where((task) => task.async).toList();
    final syncTasks = subTasks.where((task) => !task.async).toList();

    if (asyncTasks.isNotEmpty) {
      await Future.wait(asyncTasks.map(run));
    }

    if (syncTasks.isNotEmpty) {
      for (final task in syncTasks) {
        await run(task);
      }
    }
  }

  Future<void> _closeStream() async {
    if (!_updateController.isClosed) {
      await _updateController.close();
    }
  }

  @override
  List<Object?> get props => [id];
}

/// Because of the issue (https://github.com/dart-lang/sdk/issues/36983), we can't run Isolate in closures.
Future<R?> _runInIsolate<R>(
    ITask task, Future<R?> Function() run, SendPort updatePort) async {
  final exitPort = ReceivePort();
  final Completer<R?> completer = Completer();

  exitPort.listen((_) {
    completer.complete(task.result);
  });

  final option = IsolateOption.create(null, ports: [updatePort]);
  final isolate = await Isolate.spawn((IsolateOption option) async {
    option.init();

    task.listen((task) {
      option.sendData(
          [task.message, task.status, task.progress, task.error, task.result]);
    });

    await Future.delayed(const Duration(seconds: 1));

    await run();
  }, option, debugName: '${task.name}_$task.id');

  isolate.addOnExitListener(exitPort.sendPort);

  return await completer.future;
}

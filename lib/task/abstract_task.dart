import 'package:rpmlauncher/task/task_status.dart';

/// Disposable task abstract class.
abstract class ITask<R> {
  String get name;

  abstract final String id;

  /// Should run this task in an isolate.
  abstract final bool isolate;

  abstract final bool async;

  /// Default status is [TaskStatus.ready].
  /// Also see [TaskStatus].
  TaskStatus get status;

  bool get isCanceled;

  /// The value of progress should be between 0.0 and 1.0.
  /// If the value is null, it means the task is not running or **unable to calculate** the progress.
  double? get progress;

  /// Calculate the total progress of this task and all sub-tasks.
  /// This task and all sub-tasks each take up 50% of the total progress.
  double get totalProgress;

  /// The list of sub-tasks should be executed **after** this task.
  /// If this task failed, it would not be executed.
  List<ITask> get postSubTasks;

  /// The list of sub-tasks should be executed **before** this task.
  /// If the sub-tasks failed, this task would not be executed.
  List<ITask> get preSubTasks;

  /// Represents the message of the current task execution stage.
  String? get message;

  /// Will be null if the task is not failed.
  Object? get error;

  R? get result;

  /// Run the task and run all sub-tasks.
  ///
  /// The task will be executed in the following order:
  /// 1. [preExecute]
  /// 1.1. [preSubTasks]
  /// 2. [execute]
  /// 2.1. [postSubTasks] (if the task is successful)
  /// 3. [postExecute] (if the task is successful)
  Future<R?> run();

  void setStatus(TaskStatus status);

  void setProgress(double? progress);

  void setProgressByCount(int count, int total);

  void addPostSubTask(ITask task);

  void addPreSubTask(ITask task);

  void setMessage(String? message);

  /// Listen to the status, progress and message of this task.
  void listen(void Function(ITask task) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});

  void cancel();

  /// Run before the task is executed.
  Future<void> preExecute();

  /// The method to execute the task should return a result.
  Future<R> execute();

  /// Run after the task is executed successfully.
  Future<void> postExecute();
}

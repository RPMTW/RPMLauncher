import 'package:rpmlauncher/task/task.dart';

abstract class IsolateTask<R> extends Task<R> {
  IsolateTask() : super(isolate: true);
}

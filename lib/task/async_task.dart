import 'package:rpmlauncher/task/task.dart';

abstract class AsyncTask<R> extends Task<R> {
  AsyncTask() : super(async: true);
}

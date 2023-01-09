/// Task status
///
/// The status of a task can be one of the following:
///
/// * [ready] - The task is ready to be executed.
/// * [running] - The task is currently running.
/// * [success] - The task has been successfully executed.
/// * [failed] - The task has been failed.
/// * [canceled] - The task has been canceled.
enum TaskStatus {
  ready,
  running,
  success,
  failed,
  canceled,
}

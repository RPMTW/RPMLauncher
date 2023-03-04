/// Task status
///
/// The status of a task can be one of the following:
///
/// * [queued] - The task is ready to be executed.
/// * [running] - The task is currently running.
/// * [success] - The task has been successfully executed.
/// * [failed] - The task has been failed.
enum TaskStatus {
  queued,
  running,
  success,
  failed
}

enum TaskSize {
  tiny(1),
  small(2),
  medium(4),
  large(8),
  xLarge(16);

  /// The weight of a task size.
  /// The larger the weight, the more resources, and time the task will consume.
  /// The weight of a task size is used to calculate the total progress of it.
  final int weight;

  const TaskSize(this.weight);
}

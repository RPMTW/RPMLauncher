class MemoryInfo {
  /// The total of physical memory in megabytes.
  final double physical;

  const MemoryInfo(this.physical);

  int get formattedPhysical => (physical - (physical % 1024)).toInt();
}

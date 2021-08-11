class JvmArgs {
  final String args;

  const JvmArgs({
    required this.args,
  });

  factory JvmArgs.fromList(List list) => JvmArgs(args: list.join(','));

  List toList() {
    if (args.split(",").join("").isEmpty) {
      return List.empty();
    } else {
      return args.split(",");
    }
  }
}

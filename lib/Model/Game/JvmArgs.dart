class JvmArgs {
  final String args;

  const JvmArgs({
    required this.args,
  });

  factory JvmArgs.fromList(List list) => JvmArgs(args: list.join(' '));

  List<String> toList() {
    List<String> list = args.split(" ");
    if (list.join("").isEmpty) {
      return List.empty();
    } else {
      return list;
    }
  }
}

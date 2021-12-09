class JvmArgs {
  final String args;

  const JvmArgs({
    required this.args,
  });

  factory JvmArgs.fromList(List list) => JvmArgs(args: list.join(' '));

  List<String> toList() {
    List<String> _list = args.split(" ");
    if (_list.join("").isEmpty) {
      return List.empty();
    } else {
      return _list;
    }
  }
}

class Processors {
  final List<_Processor> processors;
  const Processors({
    required this.processors,
  });

  factory Processors.fromList(List processors) {
    List<_Processor> processors_ = [];
    processors.forEach(
        (processor) => processors_.add(_Processor.fromJson(processor)));
    return Processors(processors: processors_);
  }

  List<_Processor> toList() => processors;
}

class _Processor {
  final String jar;
  final List<String> classpath;
  final List<String> args;
  final Map<String, String>? outputs;

  const _Processor({
    required this.jar,
    required this.classpath,
    required this.args,
    this.outputs = null,
  });

  factory _Processor.fromJson(Map json) => _Processor(
      jar: json['jar'], classpath: json['classpath'], args: json['args']);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
      };
}

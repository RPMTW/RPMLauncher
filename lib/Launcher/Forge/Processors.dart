class Processors {
  final String jar;
  final List<String> classpath;
  final List<String> args;
  final Map<String, String>? outputs;

  const Processors({
    required this.jar,
    required this.classpath,
    required this.args,
    this.outputs = null,
  });

  factory Processors.fromJson(Map json) => Processors(
      jar: json['jar'], classpath: json['classpath'], args: json['args']);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
      };
}

import '../Libraries.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final String spec;
  final String version;
  final String path;
  final String minecraft;
  final String jsonPath;
  final Map data;
  final Processors processors;
  final Libraries libraries;

  const ForgeInstallProfile({
    required this.spec,
    required this.version,
    required this.path,
    required this.minecraft,
    required this.jsonPath,
    required this.data,
    required this.processors,
    required this.libraries,
  });

  factory ForgeInstallProfile.fromJson(Map json) => ForgeInstallProfile(
      spec: json['spec'],
      version: json['version'],
      path: json['path'],
      minecraft: json['minecraft'],
      jsonPath: json['json'],
      data: json['data'],
      processors: Processors.fromJson(json['processors']),
      libraries: Libraries.fromJson(json['libraries']));

  Map<String, dynamic> toJson() => {
        'spec': spec,
        'version': version,
        'path': path,
        'minecraft': minecraft,
        'jsonPath': jsonPath,
        'data': data,
        'processors': processors.toJson(),
        'libraries': libraries.toJson()
      };
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mc_version_java_version.g.dart';

@JsonSerializable()
class MCVersionJavaVersion extends Equatable {
  final JavaVersionComponent component;
  final int majorVersion;

  const MCVersionJavaVersion(
      {required this.component, required this.majorVersion});

  factory MCVersionJavaVersion.fromJson(Map<String, dynamic> json) {
    return _$MCVersionJavaVersionFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionJavaVersionToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [component, majorVersion];
}

@JsonEnum()
enum JavaVersionComponent {
  @JsonValue('java-runtime-alpha')
  javaRuntimeAlpha,
  @JsonValue('java-runtime-beta')
  javaRuntimeBeta,
  @JsonValue('java-runtime-gamma')
  javaRuntimeGamma,
  @JsonValue('jre-legacy')
  jreLegacy,
  @JsonValue('minecraft-java-exe')
  minecraftJavaExe
}

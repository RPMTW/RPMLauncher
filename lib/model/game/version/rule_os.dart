import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rule_os.g.dart';

@JsonSerializable()
class RuleOS extends Equatable {
  final RuleOSName? name;
  final String? version;
  final RuleOSArch? arch;

  const RuleOS({this.name, this.version, this.arch});

  factory RuleOS.fromJson(Map<String, dynamic> json) => _$RuleOSFromJson(json);

  Map<String, dynamic> toJson() => _$RuleOSToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [name];
}

@JsonEnum()
enum RuleOSName {
  linux,
  @JsonValue('osx')
  macOS,
  windows,
}

@JsonEnum()
enum RuleOSArch { x86 }

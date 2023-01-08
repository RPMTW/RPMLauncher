import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'mc_version_rule.dart';

class MCVersionArgument extends Equatable {
  final List<String> value;
  final List<MCVersionRule>? rules;

  const MCVersionArgument({
    required this.value,
    this.rules,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
      'rules': rules,
    };
  }

  factory MCVersionArgument.fromMap(dynamic map) {
    if (map is String) {
      return MCVersionArgument(value: [map]);
    }

    return MCVersionArgument(
        value: List.from(map['value'] as List),
        rules: List.from(
          (map['rules'] as List),
        ));
  }

  String toJson() => json.encode(toMap());

  factory MCVersionArgument.fromJson(String source) =>
      MCVersionArgument.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [value, rules];
}

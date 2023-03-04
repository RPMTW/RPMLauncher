import 'package:equatable/equatable.dart';
import 'mc_version_rule.dart';

class MCVersionArgument extends Equatable {
  final List<String> value;
  final List<MCVersionRule>? rules;

  const MCVersionArgument({
    required this.value,
    this.rules,
  });

  factory MCVersionArgument.fromJson(dynamic source) {
    if (source is String) {
      return MCVersionArgument(value: [source]);
    }

    List<String> value;
    if (source['value'] is String) {
      value = [source['value']];
    } else {
      value = List.from(source['value'] as List);
    }

    return MCVersionArgument(
        value: value,
        rules: (source['rules'] as List<dynamic>)
            .map((e) => MCVersionRule.fromJson(e))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'rules': rules,
    };
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [value, rules];
}

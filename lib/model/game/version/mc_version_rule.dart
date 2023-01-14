import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rpmlauncher/model/game/version/rule_os.dart';
import 'package:rpmlauncher/util/util.dart';

import 'rule_features.dart';

part 'mc_version_rule.g.dart';

@JsonSerializable()
class MCVersionRule extends Equatable {
  final RuleAction action;
  final RuleFeatures? features;
  final RuleOS? os;

  const MCVersionRule({required this.action, this.features, this.os});

  factory MCVersionRule.fromJson(Map<String, dynamic> json) =>
      _$MCVersionRuleFromJson(json);

  Map<String, dynamic> toJson() => _$MCVersionRuleToJson(this);

  bool isAllowed() {
    // Check if the rule is for the current operating system.
    final isCurrentOS = Util.getMinecraftFormatOS() == os?.name?.name;

    if (isCurrentOS) {
      return action == RuleAction.allow;
    } else {
      return true;
    }
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [action, features, os];
}

@JsonEnum()
enum RuleAction {
  allow,
  disallow,
}

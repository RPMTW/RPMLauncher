import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rule_features.g.dart';

@JsonSerializable()
class RuleFeatures extends Equatable {
  @JsonKey(name: 'is_demo_user')
  final bool? isDemoUser;
  @JsonKey(name: 'has_custom_resolution')
  final bool? hasCustomResolution;

  const RuleFeatures({this.isDemoUser, this.hasCustomResolution});

  factory RuleFeatures.fromJson(Map<String, dynamic> json) {
    return _$RuleFeaturesFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RuleFeaturesToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [isDemoUser, hasCustomResolution];
}

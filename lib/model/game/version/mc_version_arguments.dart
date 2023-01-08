import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'mc_version_argument.dart';

part 'mc_version_arguments.g.dart';

@JsonSerializable()
class MCVersionArguments extends Equatable {
  final List<MCVersionArgument> game;
  final List<MCVersionArgument> jvm;

  const MCVersionArguments({required this.game, required this.jvm});

  factory MCVersionArguments.fromJson(Map<String, dynamic> json) {
    return _$MCVersionArgumentsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionArgumentsToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [game, jvm];
}

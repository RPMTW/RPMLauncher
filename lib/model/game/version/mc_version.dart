import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rpmlauncher/model/game/version/mc_version_type.dart';

part 'mc_version.g.dart';

@JsonSerializable()
class MCVersion extends Equatable {
  final String id;
  final MCVersionType type;
  final String url;
  final DateTime time;
  final DateTime releaseTime;
  final String sha1;
  final int complianceLevel;

  const MCVersion({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.sha1,
    required this.complianceLevel,
  });

  factory MCVersion.fromJson(Map<String, dynamic> json) {
    return _$MCVersionFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      id,
      type,
      url,
      time,
      releaseTime,
      sha1,
      complianceLevel,
    ];
  }
}

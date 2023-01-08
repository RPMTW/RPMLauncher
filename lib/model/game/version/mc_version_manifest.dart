import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'mc_latest_version.dart';
import 'mc_version.dart';

part 'mc_version_manifest.g.dart';

@JsonSerializable()
class MCVersionManifest extends Equatable {
  final MCLatestVersion latest;
  final List<MCVersion> versions;

  const MCVersionManifest({required this.latest, required this.versions});

  factory MCVersionManifest.fromJson(Map<String, dynamic> json) {
    return _$MCVersionManifestFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionManifestToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [latest, versions];
}

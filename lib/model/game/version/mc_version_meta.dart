import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rpmlauncher/model/game/version/mc_version_type.dart';

import 'mc_version_arguments.dart';
import 'mc_version_asset_index.dart';
import 'mc_version_downloads.dart';
import 'mc_version_java_version.dart';
import 'mc_version_library.dart';
import 'mc_version_logging.dart';

part 'mc_version_meta.g.dart';

@JsonSerializable()
class MCVersionMeta extends Equatable {
  final MCVersionArguments? arguments;
  final MCVersionAssetIndex assetIndex;
  final String assets;
  final int complianceLevel;
  final MCVersionDownloads downloads;
  final String id;
  final MCVersionJavaVersion javaVersion;
  final List<MCVersionLibrary> libraries;
  final MCVersionLogging? logging;
  final String mainClass;
  final String? minecraftArguments;
  final int minimumLauncherVersion;
  final DateTime releaseTime;
  final DateTime time;
  final MCVersionType type;

  const MCVersionMeta({
    this.arguments,
    required this.assetIndex,
    required this.assets,
    required this.complianceLevel,
    required this.downloads,
    required this.id,
    required this.javaVersion,
    required this.libraries,
    this.logging,
    required this.mainClass,
    required this.minimumLauncherVersion,
    this.minecraftArguments,
    required this.releaseTime,
    required this.time,
    required this.type,
  });

  factory MCVersionMeta.fromJson(Map<String, dynamic> json) {
    return _$MCVersionMetaFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionMetaToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      arguments,
      assetIndex,
      assets,
      complianceLevel,
      downloads,
      id,
      javaVersion,
      libraries,
      logging,
      mainClass,
      minimumLauncherVersion,
      releaseTime,
      time,
      type,
    ];
  }
}

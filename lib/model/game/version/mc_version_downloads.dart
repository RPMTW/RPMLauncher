import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'mc_version_download.dart';
part 'mc_version_downloads.g.dart';

@JsonSerializable()
class MCVersionDownloads extends Equatable {
  final MCVersionDownload client;
  @JsonKey(name: 'client_mappings')
  final MCVersionDownload? clientMappings;
  final MCVersionDownload? server;
  @JsonKey(name: 'server_mappings')
  final MCVersionDownload? serverMappings;

  const MCVersionDownloads({
    required this.client,
    this.clientMappings,
    this.server,
    this.serverMappings,
  });

  factory MCVersionDownloads.fromJson(Map<String, dynamic> json) {
    return _$MCVersionDownloadsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionDownloadsToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      client,
      clientMappings,
      server,
      serverMappings,
    ];
  }
}

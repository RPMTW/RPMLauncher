import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mc_version_download.g.dart';

@JsonSerializable()
class MCVersionDownload extends Equatable {
  final String sha1;
  final int size;
  final String url;

  const MCVersionDownload(
      {required this.sha1, required this.size, required this.url});

  factory MCVersionDownload.fromJson(Map<String, dynamic> json) {
    return _$MCVersionDownloadFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionDownloadToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [sha1, size, url];
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mc_version_asset_index.g.dart';

@JsonSerializable()
class MCVersionAssetIndex extends Equatable {
  final String id;
  final String sha1;
  final int size;
  final int totalSize;
  final String url;

  const MCVersionAssetIndex({
    required this.id,
    required this.sha1,
    required this.size,
    required this.totalSize,
    required this.url,
  });

  factory MCVersionAssetIndex.fromJson(Map<String, dynamic> json) {
    return _$MCVersionAssetIndexFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionAssetIndexToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id, sha1, size, totalSize, url];
}

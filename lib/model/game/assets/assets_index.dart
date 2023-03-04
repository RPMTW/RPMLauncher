import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rpmlauncher/model/game/assets/asset_object.dart';

part 'assets_index.g.dart';

@JsonSerializable()
class AssetsIndex extends Equatable {
  final Map<String, AssetObject> objects;

  const AssetsIndex({required this.objects});

  factory AssetsIndex.fromJson(Map<String, dynamic> json) =>
      _$AssetsIndexFromJson(json);

  Map<String, dynamic> toJson() => _$AssetsIndexToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [objects];
}

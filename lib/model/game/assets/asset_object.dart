import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';

part 'asset_object.g.dart';

@JsonSerializable()
class AssetObject extends Equatable {
  final String hash;
  final int size;

  const AssetObject({required this.hash, required this.size});

  factory AssetObject.fromJson(Map<String, dynamic> json) =>
      _$AssetObjectFromJson(json);

  Map<String, dynamic> toJson() => _$AssetObjectToJson(this);

  String getDownloadUrl() {
    return 'https://resources.download.minecraft.net/${hash.substring(0, 2)}/$hash';
  }

  String getFilePath() {
    final directory = GameRepository.getAssetsObjectsDirectory();
    return join(directory.path, hash.substring(0, 2), hash);
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [hash, size];
}

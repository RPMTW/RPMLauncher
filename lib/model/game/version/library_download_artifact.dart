import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';

part 'library_download_artifact.g.dart';

@JsonSerializable()
class LibraryDownloadArtifact extends Equatable {
  final String path;
  final String sha1;
  final int size;
  final String url;

  const LibraryDownloadArtifact(
      {required this.path,
      required this.sha1,
      required this.size,
      required this.url});

  factory LibraryDownloadArtifact.fromJson(Map<String, dynamic> json) {
    return _$LibraryDownloadArtifactFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LibraryDownloadArtifactToJson(this);

  String getFilePath() {
    final directory = GameRepository.getLibrariesDirectory();

    return join(directory.path, path);
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [path, sha1, size, url];
}

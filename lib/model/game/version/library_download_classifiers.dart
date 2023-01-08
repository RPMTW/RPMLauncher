import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'library_download_artifact.dart';

part 'library_download_classifiers.g.dart';

@JsonSerializable()
class LibraryDownloadClassifiers extends Equatable {
  @JsonKey(name: 'natives-linux')
  final LibraryDownloadArtifact linuxNatives;
  @JsonKey(name: 'natives-osx')
  final LibraryDownloadArtifact macOSNatives;
  @JsonKey(name: 'natives-windows')
  final LibraryDownloadArtifact windowsNatives;

  const LibraryDownloadClassifiers(
      {required this.linuxNatives,
      required this.macOSNatives,
      required this.windowsNatives});

  factory LibraryDownloadClassifiers.fromJson(Map<String, dynamic> json) {
    return _$LibraryDownloadClassifiersFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LibraryDownloadClassifiersToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [linuxNatives, macOSNatives, windowsNatives];
}

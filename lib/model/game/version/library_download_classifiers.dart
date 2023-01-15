import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'library_download_artifact.dart';

part 'library_download_classifiers.g.dart';

@JsonSerializable()
class LibraryDownloadClassifiers extends Equatable {
  @JsonKey(name: 'natives-linux')
  final LibraryDownloadArtifact? linuxNatives;
  @JsonKey(name: 'natives-osx')
  final LibraryDownloadArtifact? macOSNatives;
  @JsonKey(name: 'natives-windows')
  final LibraryDownloadArtifact? windowsNatives;

  const LibraryDownloadClassifiers(
      {this.linuxNatives, this.macOSNatives, this.windowsNatives});

  factory LibraryDownloadClassifiers.fromJson(Map<String, dynamic> json) {
    return _$LibraryDownloadClassifiersFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LibraryDownloadClassifiersToJson(this);

  /// Returns the natives for the current operating system.
  LibraryDownloadArtifact? getNatives() {
    final os = Platform.operatingSystem;

    switch (os) {
      case 'linux':
        return linuxNatives;
      case 'macos':
        return macOSNatives;
      case 'windows':
        return windowsNatives;
      default:
        return null;
    }
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [linuxNatives, macOSNatives, windowsNatives];
}

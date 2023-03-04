import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'library_download_artifact.dart';
import 'library_download_classifiers.dart';

part 'library_downloads.g.dart';

@JsonSerializable()
class LibraryDownloads extends Equatable {
  final LibraryDownloadArtifact? artifact;
  final LibraryDownloadClassifiers? classifiers;

  const LibraryDownloads({this.artifact, this.classifiers});

  factory LibraryDownloads.fromJson(Map<String, dynamic> json) =>
      _$LibraryDownloadsFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryDownloadsToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [artifact, classifiers];
}

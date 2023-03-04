import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'library_downloads.dart';
import 'mc_version_rule.dart';

part 'mc_version_library.g.dart';

@JsonSerializable()
class MCVersionLibrary extends Equatable {
  final LibraryDownloads downloads;
  final String name;
  final List<MCVersionRule>? rules;

  const MCVersionLibrary(
      {required this.downloads, required this.name, this.rules});

  factory MCVersionLibrary.fromJson(Map<String, dynamic> json) {
    return _$MCVersionLibraryFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionLibraryToJson(this);

  /// Follows the rules of the library to determine whether it should be downloaded.
  bool shouldDownload() {
    return rules?.every((rule) => rule.isAllowed()) ?? true;
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [downloads, name, rules];
}

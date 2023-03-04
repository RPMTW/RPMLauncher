import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mc_latest_version.g.dart';

@JsonSerializable()
class MCLatestVersion extends Equatable {
  final String release;
  final String snapshot;

  const MCLatestVersion({required this.release, required this.snapshot});

  factory MCLatestVersion.fromJson(Map<String, dynamic> json) {
    return _$MCLatestVersionFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCLatestVersionToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [release, snapshot];
}

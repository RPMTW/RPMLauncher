import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'logging_client_file.g.dart';

@JsonSerializable()
class LoggingClientFile extends Equatable {
  final String id;
  final String sha1;
  final int size;
  final String url;

  const LoggingClientFile(
      {required this.id,
      required this.sha1,
      required this.size,
      required this.url});

  factory LoggingClientFile.fromJson(Map<String, dynamic> json) =>
      _$LoggingClientFileFromJson(json);

  Map<String, dynamic> toJson() => _$LoggingClientFileToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id, sha1, size, url];
}

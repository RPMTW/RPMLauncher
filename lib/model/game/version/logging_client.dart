import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'logging_client_file.dart';

part 'logging_client.g.dart';

@JsonSerializable()
class LoggingClient extends Equatable {
  final String argument;
  final LoggingClientFile file;
  final String type;

  const LoggingClient(this.argument, this.file, this.type);

  factory LoggingClient.fromJson(Map<String, dynamic> json) {
    return _$LoggingClientFromJson(json);
  }

  Map<String, dynamic> toJson() => _$LoggingClientToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [argument, file, type];
}

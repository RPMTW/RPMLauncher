import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'logging_client.dart';

part 'mc_version_logging.g.dart';

@JsonSerializable()
class MCVersionLogging extends Equatable {
  final LoggingClient client;

  const MCVersionLogging({required this.client});

  factory MCVersionLogging.fromJson(Map<String, dynamic> json) {
    return _$MCVersionLoggingFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MCVersionLoggingToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [client];
}

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum MCVersionType {
  release,
  snapshot,
  @JsonValue('old_beta')
  oldBeta,
  @JsonValue('old_alpha')
  oldAlpha,
}

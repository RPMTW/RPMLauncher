import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'component.g.dart';

@JsonSerializable()
class Component extends Equatable {
  final String name;
  final String identifier;
  final String version;
  final bool mainEntry;
  final bool mandatory;

  const Component({
    required this.name,
    required this.identifier,
    required this.version,
    this.mainEntry = false,
    this.mandatory = false,
  });

  factory Component.fromJson(Map<String, dynamic> json) =>
      _$ComponentFromJson(json);

  Map<String, dynamic> toJson() => _$ComponentToJson(this);

  factory Component.minecraft(String version) {
    return Component(
        name: 'Minecraft',
        identifier: 'net.minecraft',
        version: version,
        mainEntry: true,
        mandatory: true);
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [name, identifier, version, mainEntry, mandatory];
}

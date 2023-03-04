import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rpmlauncher/launcher/collection/component.dart';

part 'collection.g.dart';

@JsonSerializable()
class Collection extends Equatable {
  final String name;
  final String displayName;
  final String? notes;
  final List<Component> components;

  const Collection({
    required this.name,
    required this.displayName,
    this.notes,
    required this.components,
  });

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [name, displayName, notes, components];
}

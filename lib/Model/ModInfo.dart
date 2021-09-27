import 'package:rpmlauncher/Mod/ModLoader.dart';

class ModInfo {
  final ModLoaders loader;
  final String name;
  final String? description;
  final String? version;
  final int? curseID;
  final Map conflicts;
  final String id;
  final String file;

  const ModInfo({
    required this.loader,
    required this.name,
    required this.description,
    required this.version,
    required this.curseID,
    required this.conflicts,
    required this.id,
    required this.file,
  });
  factory ModInfo.fromList(List list) => ModInfo(
        loader: ModLoaderUttily.getByString(list[0]),
        name: list[1],
        description: list[2],
        version: list[3],
        curseID: list[4],
        conflicts: list[5],
        id: list[6],
        file: list[7],
      );

  Map<String, dynamic> toJson() => {
        'loader': loader.fixedString,
        'name': name,
        'description': description,
        'version': version,
        'curseID': curseID,
        'conflicts': conflicts,
        'id': id,
        'file': file,
      };
  List toList() =>
      [loader.fixedString, name, description, version, curseID, conflicts, id];
}

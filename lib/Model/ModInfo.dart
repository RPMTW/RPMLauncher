class ModInfo {
  final String loader;
  final String name;
  final String? description;
  final String? version;
  final int? curseID;
  final String file;
  final Map conflicts;
  final String id;
  const ModInfo({
    required this.loader,
    required this.name,
    required this.description,
    required this.version,
    required this.curseID,
    required this.file,
    required this.conflicts,
    required this.id,
  });
  factory ModInfo.fromList(List list) => ModInfo(
      loader: list[0],
      name: list[1],
      description: list[2],
      version: list[3],
      curseID: list[4],
      file: list[5],
      conflicts:list[6],
      id: list[7]
  );

  Map<String, dynamic> toJson() => {
        'loader': loader,
        'name': name,
        'description': description,
        'version': version,
        'curseID': curseID,
        'file': file,
      'conflicts':conflicts,
    'id':id,
      };
  List toList() => [loader, name, description, version, curseID,file,conflicts,id];
}
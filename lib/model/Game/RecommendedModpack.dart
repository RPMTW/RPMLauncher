import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/util/util.dart';

class RecommendedModpacks with ListMixin<RecommendedModpack> {
  List<RecommendedModpack> _list = [];

  RecommendedModpacks(this._list);

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  RecommendedModpack operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, RecommendedModpack value) {
    _list[index] = value;
  }

  factory RecommendedModpacks.fromList(List<Map<String, dynamic>> list) {
    return RecommendedModpacks(list
        .map((Map<String, dynamic> map) => RecommendedModpack.fromJson(map))
        .toList());
  }
}

class RecommendedModpack {
  final String name;
  final String description;
  final String image;
  final String? link;
  final Version version;
  final RecommendedModpackType type;
  final ModLoader loader;
  final String loaderVersion;

  final List<Map>? mods;
  final bool visible;
  final int? curseforgeID;

  RecommendedModpack(
      {required this.name,
      required this.description,
      required this.image,
      this.link,
      required this.version,
      required this.type,
      required this.loader,
      required this.loaderVersion,
      this.mods,
      required this.visible,
      this.curseforgeID});

  factory RecommendedModpack.fromJson(Map<String, dynamic> json) {
    return RecommendedModpack(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      link: json['link'],
      version: Util.parseMCComparableVersion(json['version']),
      type: RecommendedModpackType.values.byName(json['type']),
      loader: ModLoader.values.byName(json['loader']),
      loaderVersion: json['loaderVersion'],
      mods: json['mods']?.cast<Map<dynamic, dynamic>>(),
      visible: json['visible'] ?? true,
      curseforgeID: json['curseforgeID'],
    );
  }
}

enum RecommendedModpackType {
  instance,
  curseforgeModpack,
}

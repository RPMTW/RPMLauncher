import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/main.dart';

class ModInfo {
  final ModLoader loader;
  final String name;
  final String? description;
  final String? version;
  int? curseID;
  final ConflictMods? conflicts;
  final String id;
  String filePath;

  File get file => File(filePath);
  set file(File value) => filePath = value.absolute.path;

  int? _modHash;

  int get modHash => _modHash ?? Uttily.murmurhash2(file);

  set modHash(int value) => _modHash = value;

  ModInfo({
    required this.loader,
    required this.name,
    required this.description,
    required this.version,
    required this.curseID,
    this.conflicts,
    required this.id,
    required this.filePath,
  });
  factory ModInfo.fromList(List list) {
    return ModInfo(
      loader: ModLoaderUttily.getByString(list[0]),
      name: list[1],
      description: list[2],
      version: list[3],
      curseID: list[4],
      conflicts: ConflictMods.fromMap(json.decode(list[5] ?? "{}")),
      id: list[6],
      filePath: list[7],
    );
  }

  Map<String, dynamic> toJson() => {
        'loader': loader.fixedString,
        'name': name,
        'description': description,
        'version': version,
        'curseID': curseID,
        'conflicts': conflicts?.toJson(),
        'id': id,
      };
  List toList() => [
        loader.fixedString,
        name,
        description,
        version,
        curseID,
        conflicts?.toJson(),
        id
      ];

  Future<void> delete({Function? onDeleting}) async {
    await showDialog(
      context: navigator.context,
      builder: (context) {
        return AlertDialog(
          title: I18nText("gui.tips.info"),
          content: I18nText("edit.instance.mods.list.delete.check"),
          actions: [
            TextButton(
              child: Text(I18n.format("gui.cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: I18nText("gui.confirm"),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDeleting?.call();
                  try {
                    if (file.existsSync()) {
                      file.deleteSync(recursive: true);
                    }
                  } on FileSystemException {}
                })
          ],
        );
      },
    );
  }
}

class ConflictMods extends MapBase<String, ConflictMod> {
  Map<String, ConflictMod> conflictMods;

  ConflictMods(this.conflictMods);

  factory ConflictMods.fromMap(Map map) {
    Map<String, ConflictMod> _conflictMods = {};
    map.forEach((key, value) {
      _conflictMods[key] = ConflictMod(modID: key, versionID: value);
    });
    return ConflictMods(_conflictMods);
  }

  factory ConflictMods.empty() => ConflictMods({});

  @override
  ConflictMod? operator [](Object? key) {
    return conflictMods[key];
  }

  @override
  void operator []=(String key, ConflictMod value) {
    conflictMods[key] = value;
  }

  @override
  void clear() {
    conflictMods.clear();
  }

  @override
  Iterable<String> get keys => conflictMods.keys;

  @override
  ConflictMod? remove(Object? key) {
    conflictMods.remove(key);
  }

  bool isConflict(ModInfo mod) {
    return conflictMods.values
        .any((conflictMod) => conflictMod.isConflict(mod));
  }

  Map toMap() {
    Map map = {};

    conflictMods.forEach((key, value) {
      map[key] = value.versionID;
    });

    return map;
  }

  String toJson() {
    return json.encode(toMap());
  }
}

class ConflictMod {
  final String modID;
  final String versionID;

  /// 如果版本號為 * 代表任何版本都會衝突
  /// Fabric 衝突模組版本號使用 Semver 的語意版本表達規範
  bool isConflict(ModInfo mod) {
    if (versionID == "*" && mod.id == modID) return true;
    if (versionID == "*") return false;
    try {
      Version modVersion = Version.parse(mod.version!);

      VersionConstraint versionConstraint = VersionConstraint.parse(versionID);

      if (mod.id == modID && modVersion.allowsAll(versionConstraint)) {
        return true;
      } else {
        return false;
      }
    } on FormatException {
      return false;
    } catch (e, stackTrace) {
      logger.error(ErrorType.unknown, e, stackTrace: stackTrace);
      return false;
    }
  }

  ConflictMod({required this.modID, required this.versionID});
}

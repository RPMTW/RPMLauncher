import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

class ModInfo {
  final ModLoaders loader;
  final String name;
  final String? description;
  final String? version;
  final int? curseID;
  final ConflictMods? conflicts;
  final String id;
  String filePath;
  File get file => File(filePath);
  set file(File value) => filePath = value.absolute.path;

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
  factory ModInfo.fromList(List list) => ModInfo(
        loader: ModLoaderUttily.getByString(list[0]),
        name: list[1],
        description: list[2],
        version: list[3],
        curseID: list[4],
        conflicts: ConflictMods.fromMap(json.decode(list[5])),
        id: list[6],
        filePath: list[7],
      );

  Map<String, dynamic> toJson() => {
        'loader': loader.fixedString,
        'name': name,
        'description': description,
        'version': version,
        'curseID': curseID,
        'conflicts': conflicts?.toJson(),
        'id': id,
        'file': filePath,
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

  Future<void> delete() async {
    await showDialog(
      context: navigator.context,
      builder: (context) {
        return AlertDialog(
          title: i18nText("gui.tips.info"),
          content: Text("您確定要刪除此模組嗎？ (此動作將無法復原)"),
          actions: [
            TextButton(
              child: Text(i18n.format("gui.cancel")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: i18nText("gui.confirm"),
                onPressed: () {
                  Navigator.of(context).pop();
                  file.deleteSync(recursive: true);
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
    Map<String, ConflictMod> _conflictMods = <String, ConflictMod>{};
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
    Map map = <String, String>{};

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
    } catch (e) {
      logger.error(ErrorType.Unknown, e);
      return false;
    }
  }

  ConflictMod({required this.modID, required this.versionID});
}

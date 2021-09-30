import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

class ModInfo {
  final ModLoaders loader;
  final String name;
  final String? description;
  final String? version;
  final int? curseID;
  final Map conflicts;
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
    required this.conflicts,
    required this.id,
    required this.filePath,
  });
  factory ModInfo.fromList(List list) => ModInfo(
        loader: ModLoaderUttily.getByString(list[0]),
        name: list[1],
        description: list[2],
        version: list[3],
        curseID: list[4],
        conflicts: list[5],
        id: list[6],
        filePath: list[7],
      );

  Map<String, dynamic> toJson() => {
        'loader': loader.fixedString,
        'name': name,
        'description': description,
        'version': version,
        'curseID': curseID,
        'conflicts': conflicts,
        'id': id,
        'file': filePath,
      };
  List toList() =>
      [loader.fixedString, name, description, version, curseID, conflicts, id];

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

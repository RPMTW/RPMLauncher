import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/FileDeleteError.dart';

class ModInfo {
  final ModLoader loader;
  final String name;
  final String? description;
  final String? version;
  int? curseID;
  final List<ConflictMod> conflicts;
  final String id;
  String filePath;
  DateTime? lastUpdate;
  bool needsUpdate;
  Map? lastUpdateData;

  File get file => File(filePath);
  set file(File value) => filePath = value.absolute.path;

  int? _modHash;

  int get modHash => _modHash ?? Util.murmurhash2(file);

  set modHash(int value) => _modHash = value;

  Future<Widget> getImageWidget() async {
    File imageFile = GameRepository.getModIconFile(modHash.toString());
    Widget image = const Icon(Icons.image, size: 50);
    if (imageFile.existsSync()) {
      image = Image.file(imageFile, fit: BoxFit.fill);
    } else {
      if (curseID != null) {
        Map? curseforgeData = await CurseForgeHandler.getAddonInfo(curseID!);
        List<Map>? attachments = curseforgeData?['attachments']?.cast<Map>();
        if (attachments != null && attachments.isNotEmpty) {
          await RPMHttpClient().download(attachments[0]['url'], imageFile.path);
          image = Image.file(imageFile, fit: BoxFit.fill);
        }
      }
    }

    return image;
  }

  Future<bool> updating(Directory modDir) async {
    Response response = await RPMHttpClient().get(
        lastUpdateData!['downloadUrl'],
        options: Options(responseType: ResponseType.bytes));

    File newFile = File(join(modDir.path, lastUpdateData!['fileName']));

    await newFile.create(recursive: true);
    newFile.writeAsBytesSync(response.data);

    if (newFile.path != file.path) {
      await file.delete(recursive: true);
    }
    return true;
  }

  ModInfo(
      {required this.loader,
      required this.name,
      required this.description,
      required this.version,
      required this.curseID,
      required this.conflicts,
      required this.id,
      required this.filePath,
      this.lastUpdate,
      this.needsUpdate = false,
      this.lastUpdateData});

  ModInfo copyWith(
      {ModLoader? loader,
      String? name,
      String? description,
      String? version,
      int? curseID,
      List<ConflictMod>? conflicts,
      String? id,
      String? filePath,
      DateTime? lastUpdate,
      bool? needsUpdate,
      Map? lastUpdateData}) {
    return ModInfo(
        loader: loader ?? this.loader,
        name: name ?? this.name,
        description: description ?? this.description,
        version: version ?? this.version,
        curseID: curseID ?? this.curseID,
        conflicts: conflicts ?? this.conflicts,
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        needsUpdate: needsUpdate ?? this.needsUpdate,
        lastUpdateData: lastUpdateData ?? this.lastUpdateData);
  }

  Map<String, dynamic> toMap() {
    return {
      'loader': loader.name,
      'name': name,
      'description': description,
      'version': version,
      'curseID': curseID,
      'conflicts': conflicts.map((e) => e.toMap()).toList(),
      'id': id,
      'lastUpdate': lastUpdate?.millisecondsSinceEpoch,
      'needsUpdate': needsUpdate,
      'lastUpdateData': lastUpdateData
    };
  }

  factory ModInfo.fromMap(Map<String, dynamic> map, File file) {
    return ModInfo(
        loader: ModLoader.values.byName(map['loader']),
        name: map['name'],
        description: map['description'],
        version: map['version'],
        curseID: map['curseID'],
        conflicts: List<ConflictMod>.from(
            map['conflicts'].map((e) => ConflictMod.fromMap(e))),
        id: map['id'],
        filePath: file.path,
        lastUpdate: map['lastUpdate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdate'])
            : null,
        needsUpdate: map['needsUpdate'],
        lastUpdateData: map['lastUpdateData']);
  }

  String toJson() => json.encode(toMap());

  factory ModInfo.fromJson(String source, File file) =>
      ModInfo.fromMap(json.decode(source), file);

  @override
  String toString() {
    return 'ModInfo(loader: $loader, name: $name, description: $description, version: $version, curseID: $curseID, conflicts: $conflicts, id: $id, filePath: $filePath, _modHash: $_modHash lastUpdate: $lastUpdate needsUpdate: $needsUpdate lastUpdateData: $lastUpdateData)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModInfo &&
        other.loader == loader &&
        other.name == name &&
        other.description == description &&
        other.version == version &&
        other.curseID == curseID &&
        other.conflicts == conflicts &&
        other.id == id &&
        other.filePath == filePath &&
        other._modHash == _modHash &&
        other.lastUpdate == lastUpdate &&
        other.needsUpdate == needsUpdate &&
        other.lastUpdateData == lastUpdateData;
  }

  @override
  int get hashCode {
    return loader.hashCode ^
        name.hashCode ^
        description.hashCode ^
        version.hashCode ^
        curseID.hashCode ^
        conflicts.hashCode ^
        id.hashCode ^
        filePath.hashCode ^
        _modHash.hashCode ^
        lastUpdate.hashCode ^
        needsUpdate.hashCode ^
        lastUpdateData.hashCode;
  }

  Future<void> save() async {
    File indexFile = GameRepository.getModIndexFile();
    if (!await indexFile.exists()) {
      await indexFile.create(recursive: true);
      await indexFile.writeAsString(json.encode({}));
    }
    Map index = json.decode(await indexFile.readAsString());
    index[modHash.toString()] = toMap();
    await indexFile.writeAsString(json.encode(index));
  }

  Future<bool> delete({Function? onDeleting}) async {
    bool deleted = false;
    await showDialog(
      context: navigator.context,
      builder: (context) {
        return _DeleteModWidget(file: file, onDeleting: onDeleting);
      },
    );
    return deleted;
  }
}

class _DeleteModWidget extends StatelessWidget {
  const _DeleteModWidget({
    Key? key,
    required this.file,
    this.onDeleting,
  }) : super(key: key);

  final File file;
  final Function? onDeleting;

  @override
  Widget build(BuildContext context) {
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
              } on FileSystemException {
                showDialog(
                    context: context,
                    builder: (context) => const FileDeleteError());
              }
            })
      ],
    );
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

  const ConflictMod({
    required this.modID,
    required this.versionID,
  });

  Map<String, dynamic> toMap() {
    return {
      'modID': modID,
      'versionID': versionID,
    };
  }

  factory ConflictMod.fromMap(Map<String, dynamic> map) {
    return ConflictMod(
      modID: map['modID'],
      versionID: map['versionID'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConflictMod &&
        other.modID == modID &&
        other.versionID == versionID;
  }

  @override
  int get hashCode => modID.hashCode ^ versionID.hashCode;
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/widget/FileDeleteError.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;

part 'mod_info.g.dart';

@HiveType(typeId: 3)
class ModInfo extends HiveObject {
  @HiveField(0)
  final ModLoader loader;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String? version;
  @HiveField(4)
  int? curseID;
  @HiveField(5)
  final List<ConflictMod> conflicts;
  @HiveField(6)
  final String namespace;
  @HiveField(7)
  final int murmur2Hash;
  @HiveField(8)
  final String md5Hash;

  @HiveField(9)
  DateTime? lastUpdate;
  @HiveField(10)
  bool needsUpdate;
  @HiveField(11)
  Map? lastUpdateData;

  Future<Widget> getImageWidget() async {
    File imageFile = GameRepository.getModIconFile(md5Hash);
    Widget image = const Icon(Icons.image, size: 50);
    if (imageFile.existsSync()) {
      image = Image.file(imageFile, fit: BoxFit.fill);
    } else {
      if (curseID != null) {
        CurseForgeMod? mod;
        try {
          mod =
              await RPMTWApiClient.instance.curseforgeResource.getMod(curseID!);
        } catch (e) {
          mod = null;
        }

        List<CurseForgeModScreenshot>? screenshots = mod?.screenshots;
        if (screenshots != null && screenshots.isNotEmpty) {
          await RPMHttpClient().download(screenshots.first.url, imageFile.path);
          image = Image.file(imageFile, fit: BoxFit.fill);
        }
      }
    }

    return image;
  }

  Future<bool> updating(Directory modDir, File file) async {
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
      required this.namespace,
      required this.murmur2Hash,
      required this.md5Hash,
      this.lastUpdate,
      this.needsUpdate = false,
      this.lastUpdateData});

  Future<bool> deleteMod(File file, {Function? onDeleting}) async {
    bool deleted = false;
    await showDialog(
      context: navigator.context,
      builder: (context) {
        return _DeleteModWidget(file: file, onDeleting: onDeleting);
      },
    );
    return deleted;
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
        listEquals(other.conflicts, conflicts) &&
        other.namespace == namespace &&
        other.murmur2Hash == murmur2Hash &&
        other.md5Hash == md5Hash &&
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
        namespace.hashCode ^
        murmur2Hash.hashCode ^
        md5Hash.hashCode ^
        lastUpdate.hashCode ^
        needsUpdate.hashCode ^
        lastUpdateData.hashCode;
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

@HiveType(typeId: 2)
class ConflictMod {
  @HiveField(0)
  final String namespace;
  @HiveField(1)
  final String versionID;

  /// 如果版本號為 * 代表任何版本都會衝突
  /// Fabric 衝突模組版本號使用 Semver 的語意版本表達規範
  bool isConflict(ModInfo mod) {
    if (versionID == "*" && mod.namespace == namespace) return true;
    if (versionID == "*") return false;
    try {
      Version modVersion = Version.parse(mod.version!);

      VersionConstraint versionConstraint = VersionConstraint.parse(versionID);

      if (mod.namespace == namespace &&
          modVersion.allowsAll(versionConstraint)) {
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
    required this.namespace,
    required this.versionID,
  });

  Map<String, dynamic> toMap() {
    return {
      'namespace': namespace,
      'versionID': versionID,
    };
  }

  factory ConflictMod.fromMap(Map<String, dynamic> map) {
    return ConflictMod(
      namespace: map['namespace'],
      versionID: map['versionID'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConflictMod &&
        other.namespace == namespace &&
        other.versionID == versionID;
  }

  @override
  int get hashCode => namespace.hashCode ^ versionID.hashCode;
}

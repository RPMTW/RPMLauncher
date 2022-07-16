import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/screen/install_curseforge_modpack.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rwl_loading.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

class CurseForgeHandler {
  static Text parseReleaseType(CurseForgeFileReleaseType releaseType) {
    switch (releaseType) {
      case CurseForgeFileReleaseType.release:
        return Text(I18n.format("edit.instance.mods.release"),
            style: const TextStyle(color: Colors.lightGreen));
      case CurseForgeFileReleaseType.beta:
        return Text(I18n.format("edit.instance.mods.beta"),
            style: const TextStyle(color: Colors.lightBlue));
      case CurseForgeFileReleaseType.alpha:
        return Text(I18n.format("edit.instance.mods.alpha"),
            style: const TextStyle(color: Colors.red));
    }
  }

  static Widget getAddonIconWidget(CurseForgeModLogo? logo) {
    if (logo == null) return const Icon(Icons.image, size: 50);

    return Image.network(
      logo.url,
      width: 50,
      height: 50,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded.toInt() /
                  loadingProgress.expectedTotalBytes!.toInt()
              : null,
        );
      },
    );
  }

  static Future<CurseForgeModFile?> needUpdates(
      int curseID, String versionID, ModLoader loader, int hash) async {
    List<CurseForgeModFile> files =
        (await RPMTWApiClient.instance.curseforgeResource.getModFiles(curseID,
                gameVersion: versionID,
                modLoaderType: loader.toCurseForgeType()))
            .where((e) => e.gameVersions.contains(versionID))
            .toList();

    files = filterModFiles(files, versionID, loader);

    if (files.isEmpty) return null;
    final file = files.first;
    if (file.fileFingerprint != hash) {
      return file;
    }

    return null;
  }

  static Widget installModpack(File modpackFile, [String? iconUrl]) {
    final Widget error = AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format("gui.error.info")),
        content: I18nText("modpack.error.format"),
        actions: [
          TextButton(
            child: Text(I18n.format("gui.ok")),
            onPressed: () {
              Navigator.pop(navigator.context);
            },
          )
        ]);

    try {
      return FutureBuilder<Archive?>(
          future: Util.unZip(modpackFile),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final Archive? archive = snapshot.data;
              if (archive == null) {
                return error;
              }

              ArchiveFile? manifestFile = archive.findFile("manifest.json");

              if (manifestFile != null) {
                Map manifest = json.decode(
                    const Utf8Decoder(allowMalformed: true)
                        .convert(manifestFile.content));

                return WillPopScope(
                  onWillPop: () => Future.value(false),
                  child: InstallCurseForgeModpack(
                      manifest: manifest, archive: archive, iconUrl: iconUrl),
                );
              } else {
                return error;
              }
            } else {
              return AlertDialog(
                  title: I18nText("modpack.parsing"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RWLLoading(),
                    ],
                  ));
            }
          });
    } on FormatException {
      return const RWLLoading();
    }
  }

  static List<CurseForgeModFile> filterModFiles(
      List<CurseForgeModFile> files, String gameVersion, ModLoader loader,
      {bool strict = true}) {
    List<CurseForgeModFile> result = [];

    for (final file in files) {
      bool isValid = CurseForgeHandler.filterVersion(
          file.gameVersions, gameVersion, loader, strict);

      if (isValid) result.add(file);
    }

    // if strict filtering mode cannot find any files, then use non-strict filtering mode
    if (result.isEmpty && strict) {
      return filterModFiles(files, gameVersion, loader, strict: false);
    }

    return result;
  }

  static bool filterVersion(List<String> versions, String gameVersion,
      ModLoader loader, bool strict) {
    // mod loader name the first char is capitalized
    // eg. forge -> Forge, fabric -> Fabric etc.
    String loaderName = loader.name.toCapitalized();

    if (strict &&
        versions.contains(gameVersion) &&
        versions.contains(loaderName)) {
      return true;
    } else if (!strict && versions.any((v) => v.contains(gameVersion))) {
      return true;
    } else {
      return false;
    }
  }
}

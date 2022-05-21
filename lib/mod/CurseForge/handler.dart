import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;

class CurseForgeHandler {
  static int getLoaderIndex(ModLoader loader) {
    int index = 4;
    if (loader == ModLoader.fabric) {
      index = 4;
    } else if (loader == ModLoader.forge) {
      index = 1;
    }
    return index;
  }

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
        await RPMTWApiClient.instance.curseforgeResource.getModFiles(curseID,
            gameVersion: versionID, modLoaderType: loader.toCurseForgeType());
    if (files.isEmpty) return null;
    final file = files.first;
    if (file.fileFingerprint != hash) {
      return file;
    }

    return null;
  }
}

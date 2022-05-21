import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;

class CurseForgeHandler {
  static Future<List<CurseForgeMod>> getModList(
      String versionID,
      String loader,
      TextEditingController search,
      List<CurseForgeMod> beforeModList,
      int index,
      CurseForgeSortField sortField) async {
    List<CurseForgeMod> modList = beforeModList;

    RPMTWApiClient client = RPMTWApiClient.instance;
    List<CurseForgeMod> mods = await client.curseforgeResource.searchMods(
        game: CurseForgeGames.minecraft,
        index: index,
        pageSize: 20,
        gameVersion: versionID,
        modLoaderType: CurseForgeModLoaderType.values.byName(loader),
        searchFilter: search.text,
        classId: 6, // Mods
        sortField: sortField);

    /*
    filter the same curseforge mod id
    */

    mods.forEach((mod) {
      if (!(beforeModList.any((mod_) => mod_.id == mod.id))) {
        modList.add(mod);
      }
    });
    return modList;
  }

  /// 4471 -> ModPack Section ID
  static Future<List<dynamic>> getModPackList(String versionID,
      String searchFilter, List beforeList, int index, int sort) async {
    String gameVersion = versionID == I18n.format('modpack.all_version')
        ? ""
        : "&gameVersion=$versionID";
    if (searchFilter.isNotEmpty) {
      searchFilter = "&searchFilter=$searchFilter";
    }
    late List<dynamic> modPackList = beforeList;
    final url =
        "$curseForgeModAPI/addon/search?categoryId=0&gameId=432&index=$index$gameVersion&pageSize=20$searchFilter&sort=$sort&sectionId=4471";

    Response response = await RPMHttpClient().get(url);

    List<dynamic> body = await RPMHttpClient.json(response.data);
    body.forEach((pack) {
      if (!(beforeList.any((pack_) => pack_["id"] == pack["id"]))) {
        modPackList.add(pack);
      }
    });
    return modPackList.toSet().toList();
  }

  static Future<List<String>> getMCVersionList() async {
    late List<String> versionList = [];

    Response response =
        await RPMHttpClient().get("$curseForgeModAPI/minecraft/version");
    List<dynamic> body = await RPMHttpClient.json(response.data);
    body.forEach((version) {
      versionList.add(version["versionString"]);
    });

    return versionList.toList();
  }

  static Future<String> getMCVersionMetaUrl(versionID) async {
    late String url;
    http.Response response =
        await http.get(Uri.parse("$curseForgeModAPI/minecraft/version"));
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      if (version["versionString"] == versionID) {
        url = version["jsonDownloadUrl"];
        return;
      }
    });
    return url;
  }

  static int getLoaderIndex(ModLoader loader) {
    int index = 4;
    if (loader == ModLoader.fabric) {
      index = 4;
    } else if (loader == ModLoader.forge) {
      index = 1;
    }
    return index;
  }

  static Future<Map?> getAddonInfo(int curseID) async {
    Response response =
        await RPMHttpClient().get("$curseForgeModAPI/addon/$curseID");
    if (response.statusCode != 200) return null;

    return RPMHttpClient.json(response.data);
  }

  static Future<Map?> getFileInfo(curseID, fileID) async {
    final url = Uri.parse("$curseForgeModAPI/addon/$curseID/file/$fileID");
    http.Response response = await http.get(url);

    if (response.statusCode == 200) return json.decode(response.body);
    return null;
  }

  static Future<List<Map>?> getAddonFilesByVersion(
      int curseID, String versionID, ModLoader loader,
      {bool ignoreCheck = false}) async {
    List fileInfos = [];
    List<Map>? data = [];
    //  await getAddonFiles(curseID);
    if (data == null) return null;

    data.forEach((fileInfo) {
      bool checkVersion = fileInfo["gameVersion"].any((e) => e == versionID);
      bool checkLoader = fileInfo["gameVersion"]
              .any((e) => e == loader.name.toCapitalized()) ||
          ignoreCheck ||
          Util.parseMCComparableVersion(versionID) <= Version(1, 12, 2);

      /// 由於 1.12 以下版本都是 Forge 的天下，因此不偵測模組載入器
      if (checkLoader && checkVersion) {
        fileInfos.add(fileInfo);
      }
    });

    fileInfos.sort((a, b) =>
        DateTime.parse(a["fileDate"]).compareTo(DateTime.parse(b["fileDate"])));
    return fileInfos.reversed.toList().cast<Map>();
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

  static Future<int?> checkFingerPrint(int hash) async {
    int? curseID;
    final response = await http.post(
      Uri.parse("$curseForgeModAPI/fingerprint"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode([hash]),
    );

    Map body = json.decode(response.body);
    if (body["exactMatches"].length >= 1) {
      //如果完全雜湊值匹配
      curseID = body["exactMatches"][0]["id"];
    }
    return curseID;
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

  static Future<Map?> needUpdates(
      int curseID, String versionID, ModLoader loader, int hash) async {
    List<Map>? files = await getAddonFilesByVersion(curseID, versionID, loader);
    if (files == null) return null;
    if (files.isEmpty) return null;
    Map fileInfo = files[0];
    if (fileInfo['packageFingerprint'] != hash) {
      return fileInfo;
    }
    return null;
  }
}

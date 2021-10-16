import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class CurseForgeHandler {
  static Future<List<dynamic>> getModList(
      String versionID,
      String loader,
      TextEditingController search,
      List beforeModList,
      int index,
      int sort) async {
    String searchFilter = "";
    if (search.text.isNotEmpty) {
      searchFilter = "&searchFilter=${search.text}";
    }
    late List<dynamic> modList = beforeModList;

    final url = Uri.parse(
        "$CurseForgeModAPI/addon/search?gameId=432&index=$index&pageSize=20&gameVersion=$versionID&modLoaderType=${getLoaderIndex(ModLoaderUttily.getByString(loader))}$searchFilter&sort=$sort");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());

    /*
    過濾相同CurseID
    */

    body.forEach((mod) {
      if (!(beforeModList.any((mod_) => mod_["id"] == mod["id"]))) {
        modList.add(mod);
      }
    });
    return modList;
  }

  /// 4471 -> ModPack Section ID
  static Future<List<dynamic>> getModPackList(
      String versionID,
      TextEditingController search,
      List beforeList,
      int index,
      int sort) async {
    String gameVersion = versionID == i18n.format('modpack.all_version')
        ? ""
        : "&gameVersion=$versionID";
    String searchFilter = "";
    if (search.text.isNotEmpty) {
      searchFilter = "&searchFilter=${search.text}";
    }
    late List<dynamic> modPackList = beforeList;
    final url = Uri.parse(
        "$CurseForgeModAPI/addon/search?categoryId=0&gameId=432&index=$index$gameVersion&pageSize=20$searchFilter&sort=$sort&sectionId=4471");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((pack) {
      if (!(beforeList.any((pack_) => pack_["id"] == pack["id"]))) {
        modPackList.add(pack);
      }
    });
    return modPackList.toSet().toList();
  }

  static Future<List<String>> getMCVersionList() async {
    late List<String> versionList = [];

    final url = Uri.parse("$CurseForgeModAPI/minecraft/version");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      versionList.add(version["versionString"]);
    });

    return versionList.toList();
  }

  static Future<String> getMCVersionMetaUrl(versionID) async {
    late String Url;
    final url = Uri.parse("$CurseForgeModAPI/minecraft/version");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      if (version["versionString"] == versionID) {
        Url = version["jsonDownloadUrl"];
        return;
      }
    });
    return Url;
  }

  static int getLoaderIndex(ModLoaders loader) {
    int index = 4;
    if (loader == ModLoaders.fabric) {
      index = 4;
    } else if (loader == ModLoaders.forge) {
      index = 1;
    }
    return index;
  }

  static Future<dynamic> getFileInfoByVersion(int curseID, String versionID,
      String loader, fileLoader, int fileID) async {
    final url = Uri.parse("$CurseForgeModAPI/addon/$curseID/file/$fileID");
    Response response = await get(url);
    late dynamic fileInfo = json.decode(response.body.toString());
    if (!(fileInfo["gameVersion"].any((element) => element == versionID) &&
        fileLoader == getLoaderIndex(ModLoaderUttily.getByString(loader)))) {
      fileInfo = null;
    }
    return fileInfo;
  }

  static Future<dynamic> getFileInfo(curseID, fileID) async {
    final url = Uri.parse("$CurseForgeModAPI/addon/$curseID/file/$fileID");
    Response response = await get(url);
    late dynamic fileInfo = json.decode(response.body.toString());
    return fileInfo;
  }

  static Future<dynamic> getAddonFilesByVersion(
      int curseID, String versionID, String loader, fileLoader) async {
    final url = Uri.parse("$CurseForgeModAPI/addon/$curseID/files");
    Response response = await get(url);
    List fileInfos = [];
    late dynamic body = json.decode(response.body.toString());
    body.forEach((fileInfo) {
      if (fileInfo["gameVersion"].any((element) => element == versionID) &&
          fileLoader == getLoaderIndex(ModLoaderUttily.getByString(loader))) {
        fileInfos.add(fileInfo);
      }
    });
    return fileInfos.reversed.toList();
  }

  static Future<dynamic> getAddonFiles(int curseID) async {
    final url = Uri.parse("$CurseForgeModAPI/addon/$curseID/files");
    Response response = await get(url);
    late dynamic body = json.decode(response.body.toString());
    return body.reversed.toList();
  }

  static Text parseReleaseType(int releaseType) {
    late Text releaseTypeString;
    if (releaseType == 1) {
      releaseTypeString = Text(i18n.format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == 2) {
      releaseTypeString = Text(i18n.format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == 3) {
      releaseTypeString = Text(i18n.format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    }
    return releaseTypeString;
  }

  static Future<int> checkFingerPrint(File file) async {
    int curseID = 0;
    final response = await http.post(
      Uri.parse("$CurseForgeModAPI/fingerprint"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode([utility.murmurhash2(file)]),
    );

    Map body = json.decode(response.body);
    if (body["exactMatches"].length >= 1) {
      //如果完全雜湊值匹配
      curseID = body["exactMatches"][0]["id"];
    }
    return curseID;
  }
}

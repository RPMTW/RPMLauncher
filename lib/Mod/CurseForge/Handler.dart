import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class CurseForgeHandler {
  static Future<List<dynamic>> getModList(
      String VersionID,
      String Loader,
      TextEditingController Search,
      List BeforeModList,
      int Index,
      int Sort) async {
    String SearchFilter = "";
    if (Search.text.isNotEmpty) {
      SearchFilter = "&searchFilter=${Search.text}";
    }
    int categoryId = 0;
    if (Loader == ModLoader().Fabric) {
      categoryId = 4780;
    }
    late List<dynamic> ModList = BeforeModList;
    final url = Uri.parse(
        "${CurseForgeModAPI}/addon/search?categoryId=${categoryId}&gameId=432&index=${Index}&pageSize=20&gameVersion=${VersionID}${SearchFilter}&sort=${Sort}");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((mod) {
      if (!(BeforeModList.any((mod_) => mod_["id"] == mod["id"]))) {
        ModList.add(mod);
      }
    });
    return ModList.toSet().toList();
  }

  static Future<List<dynamic>> getModPackList(
      String VersionID,
      TextEditingController Search,
      List BeforeList,
      int Index,
      int Sort) async {
    /*
    4471 -> ModPack Section ID
     */
    String SearchFilter = "";
    if (Search.text.isNotEmpty) {
      SearchFilter = "&searchFilter=${Search.text}";
    }
    late List<dynamic> ModPackList = BeforeList;
    final url = Uri.parse(
        "${CurseForgeModAPI}/addon/search?categoryId=0&gameId=432&index=${Index}&pageSize=20&gameVersion=${VersionID}${SearchFilter}&sort=${Sort}&sectionId=4471");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((pack) {
      if (!(BeforeList.any((pack_) => pack_["id"] == pack["id"]))) {
        ModPackList.add(pack);
      }
    });
    return ModPackList.toSet().toList();
  }

  static Future<List<String>> getMCVersionList() async {
    late List<String> VersionList = [];

    final url = Uri.parse("${CurseForgeModAPI}/minecraft/version");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      VersionList.add(version["versionString"]);
    });

    return VersionList.toList();
  }

  static Future<String> getMCVersionMetaUrl(VersionID) async {
    late String Url;
    final url = Uri.parse("${CurseForgeModAPI}/minecraft/version");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());
    body.forEach((version) {
      if (version["versionString"] == VersionID) {
        return Url = version["jsonDownloadUrl"];
      }
    });
    return Url;
  }

  static int getLoaderIndex(Loader) {
    late int Index;
    if (Loader == ModLoader().Fabric) {
      Index = 4;
    } else if (Loader == ModLoader().Forge) {
      Index = 1;
    }
    return Index;
  }

  static Future<dynamic> getFileInfoByVersion(
      CurseID, VersionID, Loader, FileLoader, fileID) async {
    final url =
        Uri.parse("${CurseForgeModAPI}/addon/${CurseID}/file/${fileID}");
    Response response = await get(url);
    late dynamic FileInfo = json.decode(response.body.toString());
    if (!(FileInfo["gameVersion"].any((element) => element == VersionID) &&
        FileLoader == getLoaderIndex(Loader))) {
      FileInfo = null;
    }
    return FileInfo;
  }

  static Future<dynamic> getFileInfo(CurseID, fileID) async {
    final url =
        Uri.parse("${CurseForgeModAPI}/addon/${CurseID}/file/${fileID}");
    Response response = await get(url);
    late dynamic FileInfo = json.decode(response.body.toString());
    return FileInfo;
  }

  static Future<dynamic> getAddonFilesByVersion(
      CurseID, VersionID, Loader, FileLoader) async {
    final url = Uri.parse("${CurseForgeModAPI}/addon/${CurseID}/files");
    Response response = await get(url);
    List FilesInfo = [];
    late dynamic body = json.decode(response.body.toString());
    body.forEach((FileInfo) {
      if (FileInfo["gameVersion"].any((element) => element == VersionID) &&
          FileLoader == getLoaderIndex(Loader)) {
        FilesInfo.add(FileInfo);
      }
    });
    return FilesInfo.reversed.toList();
  }

  static Future<dynamic> getAddonFiles(CurseID) async {
    final url = Uri.parse("${CurseForgeModAPI}/addon/${CurseID}/files");
    Response response = await get(url);
    late dynamic body = json.decode(response.body.toString());
    return body.reversed.toList();
  }

  static Text ParseReleaseType(int releaseType) {
    late Text ReleaseTypeString;
    if (releaseType == 1) {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == 2) {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == 3) {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    }
    return ReleaseTypeString;
  }

  static Future<int> CheckFingerprint(File file) async {
    int CurseID = 0;
    final response = await http.post(
      Uri.parse("${CurseForgeModAPI}/fingerprint"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode([utility.murmurhash2(file)]),
    );

    Map body = json.decode(response.body);
    if (body["exactMatches"].length >= 1) {
      //如果完全雜湊值匹配
      CurseID = body["exactMatches"][0]["id"];
    }
    return CurseID;
  }
}

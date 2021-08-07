import 'dart:convert';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

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

  static int getLoaderIndex(Loader) {
    late int Index;
    if (Loader == ModLoader().Fabric) {
      Index = 4;
    } else if (Loader == ModLoader().Forge) {
      Index = 1;
    }
    return Index;
  }

  static Future<dynamic> getFileInfo(
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

  static Future<dynamic> getModFiles(
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
}

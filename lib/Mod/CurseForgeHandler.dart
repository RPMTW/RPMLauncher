import 'dart:convert';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class CurseForgeHandler {
  static Future<List<dynamic>> getModList(
      String VersionID, String Loader, TextEditingController Search) async {
    List<dynamic> ModList = [];
    String SearchFilter = "";
    if (Search.text.isNotEmpty) {
      SearchFilter = "&searchFilter=${Search.text}";
    }
    final url = Uri.parse(
        "${CurseForgeModAPI}/addon/search?categoryId=0&gameId=432&index=0&pageSize=50&gameVersion=${VersionID}${SearchFilter}");
    Response response = await get(url);
    List<dynamic> body = await json.decode(response.body.toString());

    body.forEach((mods) {
      if (mods.containsKey("gameVersionLatestFiles") &&
          mods["gameVersionLatestFiles"].any(
              (element) => element["modLoader"] == getLoaderIndex(Loader))) {
        ModList.add(mods);
      }
    });

    return ModList;
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

  static Future<dynamic> getFileInfo(CurseID, VersionID, Loader,FileLoader, fileID) async {
    final url =
        Uri.parse("${CurseForgeModAPI}/addon/${CurseID}/file/${fileID}");
    Response response = await get(url);
    late dynamic FilesInfo = json.decode(response.body.toString());
    if (!(FilesInfo["gameVersion"].any((element) => element == VersionID) && FileLoader == getLoaderIndex(Loader))) {
      FilesInfo = null;
    }
    return FilesInfo;
  }

  static Text ParseReleaseType(int releaseType) {
    late Text ReleaseTypeString;
    if (releaseType == 1) {
      ReleaseTypeString = Text("Release",style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == 2) {
      ReleaseTypeString = Text("Beta",style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == 3) {
      ReleaseTypeString = Text("Alpha",style: TextStyle(color: Colors.red));
    }
    return ReleaseTypeString;
  }
}

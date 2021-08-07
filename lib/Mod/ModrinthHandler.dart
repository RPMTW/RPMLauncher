import 'dart:convert';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ModrinthHandler {
  static Future<List<dynamic>> getModList(String VersionID, String Loader,
      TextEditingController Search, List BeforeModList, int Index, Sort) async {
    String SearchFilter = "";
    if (Search.text.isNotEmpty) {
      SearchFilter = "&query=${Search.text}";
    }
    List ModList = BeforeModList;
    final url = Uri.parse(
        "${ModrinthAPI}/mod?facets=[[\"versions:${VersionID}\"],[\"categories:${Loader}\"]]${SearchFilter}&offset=${20 * Index}&limit=20&index=${Sort}");
    Response response = await get(url);
    var body = await json.decode(response.body.toString());
    ModList.addAll(body["hits"]);
    return ModList;
  }

  static Future<List<dynamic>> getModFilesInfo(
      ModrinthID, VersionID, Loader) async {
    final url = Uri.parse("${ModrinthAPI}/mod/${ModrinthID}/version");
    Response response = await get(url);
    late List<dynamic> FilesInfo = [];
    late dynamic ModVersions = json.decode(response.body.toString());
    await ModVersions.forEach((versions) {
      if (versions["game_versions"].any((element) => element == VersionID) &&
          versions["loaders"].any((element) => element == Loader)) {
        FilesInfo.add(versions);
      }
    });
    return FilesInfo;
  }

  static Text ParseReleaseType(String releaseType) {
    late Text ReleaseTypeString;
    if (releaseType == "release") {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "beta") {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "alpha") {
      ReleaseTypeString = Text(i18n.Format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.lightGreen));
    }
    return ReleaseTypeString;
  }
}

import 'dart:convert';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ModrinthHandler {
  static Future<List<dynamic>> getModList(String versionID, String Loader,
      TextEditingController Search, List BeforeModList, int index, sort) async {
    String searchFilter = "";
    if (Search.text.isNotEmpty) {
      searchFilter = "&query=${Search.text}";
    }
    List ModList = BeforeModList;
    final url = Uri.parse(
        "$modrinthAPI/mod?facets=[[\"versions:$versionID\"],[\"categories:$Loader\"]]$searchFilter&offset=${20 * index}&limit=20&index=$sort");
    Response response = await get(url);
    var body = await json.decode(response.body.toString());
    ModList.addAll(body["hits"]);
    return ModList;
  }

  static Future<List<dynamic>> getModFilesInfo(
      modrinthID, versionID, Loader) async {
    final url = Uri.parse("$modrinthAPI/mod/$modrinthID/version");
    Response response = await get(url);
    late List<dynamic> filesInfo = [];
    late dynamic modVersions = json.decode(response.body.toString());
    await modVersions.forEach((versions) {
      if (versions["game_versions"].any((element) => element == versionID) &&
          versions["loaders"].any((element) => element == Loader)) {
        filesInfo.add(versions);
      }
    });
    return filesInfo;
  }

  static Text parseReleaseType(String releaseType) {
    late Text releaseTypeString;
    if (releaseType == "release") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "beta") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == "alpha") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    }
    return releaseTypeString;
  }

  static Text parseSide(String sideString, String side, Map data) {
    Text parse(Side, text) {
      late Text sideText;
      if (text == "required") {
        sideText = Text(
          Side + I18n.format("edit.instance.mods.side.required"),
          style: TextStyle(color: Colors.red),
        );
      } else if (text == "optional") {
        sideText = Text(
          Side + I18n.format("edit.instance.mods.side.optional"),
          style: TextStyle(color: Colors.lightGreenAccent),
        );
      } else if (text == "unsupported") {
        sideText = Text(
          Side + I18n.format("edit.instance.mods.side.unsupported"),
          style: TextStyle(color: Colors.grey),
        );
      }
      return sideText;
    }

    return parse(sideString, data[side]);
  }
}

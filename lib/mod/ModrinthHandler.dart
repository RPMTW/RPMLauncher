import 'dart:convert';

import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ModrinthHandler {
  static Future<List<dynamic>> getModList(String versionID, String loader,
      TextEditingController search, List beforeModList, int index, sort) async {
    String searchFilter = "";
    if (search.text.isNotEmpty) {
      searchFilter = "&query=${search.text}";
    }
    List modList = beforeModList;
    final url = Uri.parse(
        "$modrinthAPI/mod?facets=[[\"versions:$versionID\"],[\"categories:$loader\"]]$searchFilter&offset=${20 * index}&limit=20&index=$sort");
    Response response = await get(url);
    var body = await json.decode(response.body.toString());
    modList.addAll(body["hits"]);
    return modList;
  }

  static Future<List<dynamic>> getModFilesInfo(
      modrinthID, versionID, loader) async {
    final url = Uri.parse("$modrinthAPI/mod/$modrinthID/version");
    Response response = await get(url);
    late List<dynamic> filesInfo = [];
    late dynamic modVersions = json.decode(response.body.toString());
    await modVersions.forEach((versions) {
      if (versions["game_versions"].any((element) => element == versionID) &&
          versions["loaders"].any((element) => element == loader)) {
        filesInfo.add(versions);
      }
    });
    return filesInfo;
  }

  static Text parseReleaseType(String releaseType) {
    late Text releaseTypeString;
    if (releaseType == "release") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.release"),
          style: const TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "beta") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.beta"),
          style: const TextStyle(color: Colors.lightBlue));
    } else if (releaseType == "alpha") {
      releaseTypeString = Text(I18n.format("edit.instance.mods.alpha"),
          style: const TextStyle(color: Colors.red));
    }
    return releaseTypeString;
  }

  static Text parseSide(String sideString, String side, Map data) {
    Text parse(sideName, type) {
      late final Text sideText;
      if (type == "required") {
        sideText = Text(
          sideName + I18n.format("edit.instance.mods.side.required"),
          style: const TextStyle(color: Colors.red),
        );
      } else if (type == "optional") {
        sideText = Text(
          sideName + I18n.format("edit.instance.mods.side.optional"),
          style: const TextStyle(color: Colors.lightGreenAccent),
        );
      } else if (type == "unsupported") {
        sideText = Text(
          sideName + I18n.format("edit.instance.mods.side.unsupported"),
          style: const TextStyle(color: Colors.grey),
        );
      }

      return sideText;
    }

    return parse(sideString, data[side]);
  }
}

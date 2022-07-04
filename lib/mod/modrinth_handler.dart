import 'package:dio/dio.dart';
import 'package:rpmlauncher/launcher/apis.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';

class ModrinthHandler {
  static Future<List<dynamic>> getModList(String versionID, String loader,
      TextEditingController search, List beforeModList, int index, sort) async {
    String searchFilter = '';
    if (search.text.isNotEmpty) {
      searchFilter = '&query=${search.text}';
    }
    List modList = beforeModList;
    Response response = await RPMHttpClient().get(
        '$modrinthAPI/search?facets=[["versions:$versionID"],["categories:$loader"],["project_type:mod"]]$searchFilter&offset=${20 * index}&limit=20&index=$sort');
    Map body = RPMHttpClient.json(response);
    modList.addAll(body['hits']);
    return modList;
  }

  static Future<List<dynamic>> getModFilesInfo(
      modrinthID, versionID, loader) async {
    Response response =
        await RPMHttpClient().get('$modrinthAPI/project/$modrinthID/version');
    late List<dynamic> filesInfo = [];

    List<Map> modVersions = RPMHttpClient.json(response).cast<Map>();
    modVersions.forEach((versions) {
      if (versions['game_versions'].any((element) => element == versionID) &&
          versions['loaders'].any((element) => element == loader)) {
        filesInfo.add(versions);
      }
    });
    return filesInfo;
  }

  static Text parseReleaseType(String releaseType) {
    late Text releaseTypeString;
    if (releaseType == 'release') {
      releaseTypeString = Text(I18n.format('edit.instance.mods.release'),
          style: const TextStyle(color: Colors.lightGreen));
    } else if (releaseType == 'beta') {
      releaseTypeString = Text(I18n.format('edit.instance.mods.beta'),
          style: const TextStyle(color: Colors.lightBlue));
    } else if (releaseType == 'alpha') {
      releaseTypeString = Text(I18n.format('edit.instance.mods.alpha'),
          style: const TextStyle(color: Colors.red));
    }
    return releaseTypeString;
  }

  static Text parseSide(String sideString, String side, Map data) {
    Text parse(sideName, type) {
      late final Text sideText;
      if (type == 'required') {
        sideText = Text(
          sideName + I18n.format('edit.instance.mods.side.required'),
          style: const TextStyle(color: Colors.red),
        );
      } else if (type == 'optional') {
        sideText = Text(
          sideName + I18n.format('edit.instance.mods.side.optional'),
          style: const TextStyle(color: Colors.lightGreenAccent),
        );
      } else if (type == 'unsupported') {
        sideText = Text(
          sideName + I18n.format('edit.instance.mods.side.unsupported'),
          style: const TextStyle(color: Colors.grey),
        );
      }

      return sideText;
    }

    return parse(sideString, data[side]);
  }
}

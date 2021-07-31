import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';

class ForgeAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body["promos"].containsKey("${VersionID}-latest");
  }

  Future<String> GetLoaderVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body["promos"]["${VersionID}-latest"];
  }

  Future<String> GetProfileJson(VersionID) async {
    /*
     這裡使用MultiMC的元數據庫，由於未找到更好的方式解析ForgeAPI。
     The MultiMC metadata library is used here, as no better way to parse the Forge API has been found.
    */
    final url = Uri.parse(
        "${MultiMCMetaForgeApi}/forge/version_manifests/${VersionID}-${await GetLoaderVersion(VersionID)}.json");
    Response response = await get(url);
    return response.body;
  }
}

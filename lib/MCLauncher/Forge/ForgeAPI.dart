import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';

class ForgeAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url =
    Uri.parse(ForgeLatestVersionAPI);
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

  //
  // Future<String> GetProfileJson(VersionID) async {
  //   final url = Uri.parse("${FabricApi}/versions/loader/${VersionID}/${await GetLoaderVersion(VersionID)}/profile/json");
  //   Response response = await get(url);
  //   return response.body;
  // }
}
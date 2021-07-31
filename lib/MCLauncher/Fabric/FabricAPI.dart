import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';

class FabricAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url =
        Uri.parse("${FabricApi}/versions/intermediary/${VersionID}");
    Response response = await get(url);
    return await response.body.contains("maven");
  }

  Future<String> GetLoaderVersion(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/loader/${VersionID}");
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    return body[0]["loader"]["version"];
  }

  Future<String> GetProfileJson(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/loader/${VersionID}/${GetLoaderVersion(VersionID)}/profile/json");
    Response response = await get(url);
    return response.body;
  }
}

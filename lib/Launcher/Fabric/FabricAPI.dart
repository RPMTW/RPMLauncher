import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';

class FabricAPI {
  Future<List<dynamic>> getLoaderVersions(versionID) async {
    final url = Uri.parse("$fabricApi/versions/loader/$versionID");
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body;
  }

  Future<String> getProfileJson(versionID, loaderVersion) async {
    final url = Uri.parse(
        "$fabricApi/versions/loader/$versionID/$loaderVersion/profile/json");
    Response response = await get(url);
    return response.body;
  }
}

import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';

class FabricAPI {
  Future<bool> isCompatibleVersion(versionID) async {
    final url = Uri.parse("$FabricApi/versions/intermediary/$versionID");
    Response response = await get(url);
    return response.body.contains("version");
  }

  Future<List<dynamic>> getLoaderVersions(versionID) async {
    final url = Uri.parse("$FabricApi/versions/loader/$versionID");
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body;
  }

  Future<String> getProfileJson(versionID, LoaderVersion) async {
    final url = Uri.parse(
        "$FabricApi/versions/loader/$versionID/$LoaderVersion/profile/json");
    Response response = await get(url);
    return response.body;
  }
}

// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';

class FabricAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse("$FabricApi/versions/intermediary/$VersionID");
    Response response = await get(url);
    return response.body.contains("version");
  }

  Future<List<dynamic>> getLoaderVersions(VersionID) async {
    final url = Uri.parse("$FabricApi/versions/loader/$VersionID");
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body;
  }

  Future<String> getProfileJson(VersionID, LoaderVersion) async {
    final url = Uri.parse(
        "$FabricApi/versions/loader/$VersionID/$LoaderVersion/profile/json");
    Response response = await get(url);
    return response.body;
  }
}

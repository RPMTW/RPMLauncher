import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/path.dart';

class FabricAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/intermediary/${VersionID}");
    Response response = await get(url);
    return await response.body.contains("version");
  }

  Future<List<dynamic>> GetLoaderVersions(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/loader/${VersionID}");
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body;
  }

  Future<String> GetProfileJson(VersionID, LoaderVersion) async {
    final url = Uri.parse(
        "${FabricApi}/versions/loader/${VersionID}/${LoaderVersion}/profile/json");
    Response response = await get(url);
    return response.body;
  }
}

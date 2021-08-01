import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/path.dart';

class FabricAPI {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/intermediary/${VersionID}");
    Response response = await get(url);
    return await response.body.contains("maven");
  }

  Future<String> GetLoaderVersion(VersionID) async {
    final url = Uri.parse("${FabricApi}/versions/loader/${VersionID}");
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body[0]["loader"]["version"];
  }

  Future<String> GetProfileJson(VersionID) async {
    final url = Uri.parse(
        "${FabricApi}/versions/loader/${VersionID}/${await GetLoaderVersion(VersionID)}/profile/json");
    Response response = await get(url);
    return response.body;
  }

  String GetLibraryFiles(VersionID, ClientJar) {
    var LibraryDir = Directory(join(dataHome.absolute.path, "versions",
            VersionID, "libraries", ModLoader().Fabric))
        .listSync(recursive: true, followLinks: true);
    var LibraryFiles = ClientJar + utility.GetSeparator();
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += i.absolute.path + utility.GetSeparator();
      }
    }
    return LibraryFiles;
  }
}

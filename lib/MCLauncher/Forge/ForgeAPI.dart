import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../../path.dart';

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

  Future<Uri> GetForgeInstaller(VersionID) async {
    String version = "${VersionID}-${await GetLoaderVersion(VersionID)}";
    final url =
        Uri.parse("${ForgeInstallerAPI}/${version}/forge-${version}-installer.jar");
    return url;
  }

  Future<String> GetProfileJson(VersionID) async {
    /*
     Forge 目前只能透過解壓縮安裝程式來取得資料
    */
   late File VersionFile;
    Uri InstallUrl = await GetForgeInstaller(VersionID);
    await http.get(InstallUrl).then((response) async{
      final archive = await ZipDecoder().decodeBytes(response.bodyBytes);
      for (final file in archive) {
        if (file.isFile && file.name == "version.json") {
          final data = file.content as List<int>;
          VersionFile = File(join(dataHome.absolute.path, "versions", VersionID, "${ModLoader().Forge}_version.json"));
          VersionFile.createSync(recursive: true);
          VersionFile.writeAsBytesSync(data);
          return;
        }
      }
    });
    return await VersionFile.readAsStringSync();
  }

  String GetLibraryFiles(VersionID, ClientJar) {
    var LibraryDir = Directory(join(dataHome.absolute.path, "versions",
        VersionID, "libraries", ModLoader().Forge))
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

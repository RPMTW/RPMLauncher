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

  Future<String> GetGameLoaderVersion(VersionID) async {
    return "${VersionID}-forge-${await GetLoaderVersion(VersionID)}";
  }

  Future DownloadForgeInstaller(VersionID) async {
    String version = await GetGameLoaderVersion(VersionID);
    String LoaderVersion = "${VersionID}-${await GetLoaderVersion(VersionID)}";
    final url = Uri.parse(
        "${ForgeInstallerAPI}/${LoaderVersion}/forge-${LoaderVersion}-installer.jar");
    var JarFile = File(join(
        dataHome.absolute.path, "TempData", "forge-installer", "$version.jar"));
    await http.get(url).then((response) {
      JarFile.writeAsBytesSync(response.bodyBytes);
    });
  }

  Future<String> GetVersionJson(VersionID) async {
    /*
     Forge 目前只能透過解壓縮安裝程式來取得資料
    */

    late File VersionFile;
    File InstallerFile = File(join(dataHome.absolute.path, "TempData",
        "forge-installer", "${await GetGameLoaderVersion(VersionID)}.jar"));
    final archive =
        await ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    for (final file in archive) {
      if (file.isFile && file.name == "version.json") {
        final data = file.content as List<int>;
        VersionFile = File(join(dataHome.absolute.path, "versions", VersionID,
            "${ModLoader().Forge}_version.json"));
        VersionFile.createSync(recursive: true);
        VersionFile.writeAsBytesSync(data);
        break;
      }
    }
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

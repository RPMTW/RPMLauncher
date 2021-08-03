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

  Future<String> DownloadForgeInstaller(VersionID) async {
    String version = await GetGameLoaderVersion(VersionID);
    String LoaderVersion = "${VersionID}-${await GetLoaderVersion(VersionID)}";
    final url = Uri.parse(
        "${ForgeInstallerAPI}/${LoaderVersion}/forge-${LoaderVersion}-installer.jar");
    var JarFile = File(join(
        Directory.systemTemp.absolute.path, "forge-installer", "$version.jar"));
    await http.get(url).then((response) {
      JarFile.writeAsBytesSync(response.bodyBytes);
    });
    return version;
  }

  Future<Map> GetVersionJson(VersionID, Archive archive) async {
    late File VersionFile;
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
    return json.decode(VersionFile.readAsStringSync());
  }

  Future<Map> GetProfileJson(VersionID, Archive archive) async {
    late File ProfileJson;
    for (final file in archive) {
      if (file.isFile && file.name == "install_profile.json") {
        final data = file.content as List<int>;
        ProfileJson = File(join(dataHome.absolute.path, "versions", VersionID,
            "${ModLoader().Forge}_install_profile.json"));
        ProfileJson.createSync(recursive: true);
        ProfileJson.writeAsBytesSync(data);
        break;
      }
    }
    return await json.decode(ProfileJson.readAsStringSync());
  }

  Future GetForgeJar(VersionID, Archive archive) async {
    for (final file in archive) {
      if (file.isFile &&
          file.toString().startsWith("maven/net/minecraftforge/forge/")) {
        final data = file.content as List<int>;
        File JarFile = File(join(dataHome.absolute.path, "versions", VersionID,
            file.name.split("maven/").join("")));
        JarFile.createSync(recursive: true);
        JarFile.writeAsBytesSync(data);
      }
    }
  }

  String GetLibraryFiles(VersionID, ClientJar) {
    var LibraryDir = Directory(
            join(dataHome.absolute.path, "versions", VersionID, "libraries"))
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

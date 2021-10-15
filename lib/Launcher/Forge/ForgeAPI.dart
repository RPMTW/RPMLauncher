// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Forge/ForgeInstallProfile.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';

import '../../Model/Libraries.dart';

class ForgeAPI {
  static Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body["promos"].containsKey("$VersionID-latest");
  }

  static Future<String> getLatestLoaderVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body["promos"]["$VersionID-latest"];
  }

  static Future<List> getAllLoaderVersion(VersionID) async {
    final url = Uri.parse("$ForgeFilesMainAPI/maven-metadata.json");
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body[VersionID].reversed.toList();
  }

  // net/minecraftforge/forge/maven-metadata.json

  static String getGameLoaderVersion(VersionID, forgeVersionID) {
    return "$VersionID-forge-$forgeVersionID";
  }

  static Future<ForgeInstallProfile> getProfile(
      VersionID, Archive archive) async {
    late Map ProfileJson;
    late Map VersionJson;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == "install_profile.json") {
          final data = file.content as List<int>;
          ProfileJson =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data));
        } else if (file.name == "version.json") {
          final data = file.content as List<int>;
          VersionJson =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data));
        }
      }
    }

    ForgeInstallProfile Profile =
        ForgeInstallProfile.fromJson(ProfileJson, VersionJson);
    File ProfileJsonFile = File(join(dataHome.absolute.path, "versions",
        VersionID, "${ModLoaders.forge.fixedString}_install_profile.json"));
    ProfileJsonFile.createSync(recursive: true);
    ProfileJsonFile.writeAsStringSync(json.encode(Profile.toJson()));
    return Profile;
  }

  static Future getForgeJar(VersionID, Archive archive) async {
    for (final file in archive) {
      if (file.isFile &&
          file.toString().startsWith("maven/net/minecraftforge/forge/")) {
        final data = file.content as List<int>;
        File JarFile = File(join(
            GameRepository.getLibraryGlobalDir().absolute.path,
            file.name.split("maven/").join("")));
        JarFile.createSync(recursive: true);
        JarFile.writeAsBytesSync(data);
      }
    }
  }

  static List ParseMaven(String MavenString) {
    /*
    原始內容: de.oceanlabs.mcp:mcp_config:1.16.5-20210115.111550@zip
    轉換後內容: https://maven.minecraftforge.net/de/oceanlabs/mcp/mcp_config/1.16.5-20210115.110354/mcp_config-1.16.5-20210115.110354.zip

    . -> / (套件包名稱)
    : -> /
    第一個 : 後面代表套件名稱，第二個 : 後面代表版本號
    @ -> . (副檔名)
    檔案名稱組合方式: 套件名稱-套件版本號/.副檔名 (例如: mcp_config-1.16.5-20210115.110354.zip)
    */

    /// 是否為方括號，例如這種格式: [de.oceanlabs.mcp:mcp_config:1.16.5-20210115.111550@zip]
    if (utility.isSurrounded(MavenString, "[", "]")) {
      MavenString =
          MavenString.split("[").join("").split("]").join(""); //去除方括號，方便解析
    }

    /// 以下範例的原始字串為 de.oceanlabs.mcp:mcp_config:1.16.5-20210115.111550@zip 的格式
    /// 結果: de/oceanlabs/mcp
    String PackageGroup = MavenString.split(":")[0].replaceAll(".", "/");

    /// 結果: mcp_config
    String PackageName = MavenString.split(":")[1];

    /// 結果: 1.16.5-20210115.111550
    String PackageVersion = MavenString.split(":")[2].split("@")[0];

    /// 結果: zip
    String PackageExtension = MavenString.split("@")[1];

    return [
      "$PackageGroup/$PackageName/$PackageVersion",
      "$PackageName-$PackageVersion.$PackageExtension"
    ];
  }

  static File getLibFile(
      List<Library> libraries, String ForgeVersionID, String LibName) {
    List split_ = libraries
        .firstWhere((lib) => lib.name == LibName)
        .downloads
        .artifact
        .path
        .split("/");
    return File(join(
      dataHome.absolute.path,
      "temp",
      "forge-installer",
      ForgeVersionID,
      "libraries",
      split_.join(Platform.pathSeparator),
    ));
  }
}

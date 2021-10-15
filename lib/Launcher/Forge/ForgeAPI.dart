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
  static Future<bool> isCompatibleVersion(versionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body["promos"].containsKey("$versionID-latest");
  }

  static Future<String> getLatestLoaderVersion(versionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body["promos"]["$versionID-latest"];
  }

  static Future<List> getAllLoaderVersion(versionID) async {
    final url = Uri.parse("$ForgeFilesMainAPI/maven-metadata.json");
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body[versionID].reversed.toList();
  }

  // net/minecraftforge/forge/maven-metadata.json

  static String getGameLoaderVersion(versionID, forgeVersionID) {
    return "$versionID-forge-$forgeVersionID";
  }

  static Future<ForgeInstallProfile> getProfile(
      versionID, Archive archive) async {
    late Map profileJson;
    late Map versionJson;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == "install_profile.json") {
          final data = file.content as List<int>;
          profileJson =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data));
        } else if (file.name == "version.json") {
          final data = file.content as List<int>;
          versionJson =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data));
        }
      }
    }

    ForgeInstallProfile profile =
        ForgeInstallProfile.fromJson(profileJson, versionJson);
    File profileJsonFile = File(join(dataHome.absolute.path, "versions",
        versionID, "${ModLoaders.forge.fixedString}_install_profile.json"));
    profileJsonFile.createSync(recursive: true);
    profileJsonFile.writeAsStringSync(json.encode(profile.toJson()));
    return profile;
  }

  static Future getForgeJar(versionID, Archive archive) async {
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

  static List parseMaven(String mavenString) {
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
    if (utility.isSurrounded(mavenString, "[", "]")) {
      mavenString =
          mavenString.split("[").join("").split("]").join(""); //去除方括號，方便解析
    }

    /// 以下範例的原始字串為 de.oceanlabs.mcp:mcp_config:1.16.5-20210115.111550@zip 的格式
    /// 結果: de/oceanlabs/mcp
    String packageGroup = mavenString.split(":")[0].replaceAll(".", "/");

    /// 結果: mcp_config
    String packageName = mavenString.split(":")[1];

    /// 結果: 1.16.5-20210115.111550
    String packageVersion = mavenString.split(":")[2].split("@")[0];

    /// 結果: zip
    String packageExtension = mavenString.split("@")[1];

    return [
      "$packageGroup/$packageName/$packageVersion",
      "$packageName-$packageVersion.$packageExtension"
    ];
  }

  static File getLibFile(
      List<Library> libraries, String forgeVersionID, String libraryName) {
    List split_ = libraries
        .firstWhere((lib) => lib.name == libraryName)
        .downloads
        .artifact
        .path
        .split("/");
    return File(join(
      dataHome.absolute.path,
      "temp",
      "forge-installer",
      forgeVersionID,
      "libraries",
      split_.join(Platform.pathSeparator),
    ));
  }
}

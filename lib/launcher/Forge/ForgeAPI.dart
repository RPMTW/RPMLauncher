import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeInstallProfile.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/util/util.dart';

class ForgeAPI {
  static Future<List> getAllLoaderVersion(versionID) async {
    final url = Uri.parse("$forgeFilesMainAPI/maven-metadata.json");
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body[versionID].reversed.toList();
  }

  // net/minecraftforge/forge/maven-metadata.json

  static String getGameLoaderVersion(versionID, forgeVersionID) {
    return "$versionID-forge-$forgeVersionID";
  }

  static Future<ForgeInstallProfile?> getProfile(
      versionID, Archive archive) async {
    Map<String, dynamic>? profileJson;
    Map? versionJson;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name == "install_profile.json") {
          final data = file.content as List<int>;
          profileJson = json
              .decode(const Utf8Decoder(allowMalformed: true).convert(data))
              .cast<String, dynamic>();
        } else if (file.name == "version.json") {
          final data = file.content as List<int>;
          versionJson = json
              .decode(const Utf8Decoder(allowMalformed: true).convert(data));
        }
      }
    }

    if (profileJson == null) return null;

    ForgeInstallProfile? profile;
    if (versionJson == null && profileJson['install'] != null) {
      /// Forge 14.23.5.2840 版本以前的格式
      profile = ForgeInstallProfile.fromOldJson(profileJson);
    } else if (versionJson != null) {
      profile = ForgeInstallProfile.fromNewJson(profileJson,
          versionJson: versionJson);
    } else {
      return null;
    }

    File profileJsonFile = GameRepository.getForgeProfileFile(versionID);
    await profileJsonFile.create(recursive: true);
    await profileJsonFile.writeAsString(json.encode(profile.toJson()));
    return profile;
  }

  static Future getForgeJar(
      versionID, Archive archive, ForgeInstallProfile installProfile) async {
    for (final file in archive) {
      if (file.isFile) {
        if (file.toString().startsWith("maven/net/minecraftforge/forge/")) {
          final data = file.content as List<int>;
          File jarFile = File(join(
              GameRepository.getLibraryGlobalDir().absolute.path,
              file.name.split("maven/").join("")));
          jarFile.createSync(recursive: true);
          jarFile.writeAsBytesSync(data);
        } else if (installProfile.filePath != null &&
            file.toString() == installProfile.filePath) {
          final data = file.content as List<int>;

          List<String> path = [GameRepository.getLibraryGlobalDir().path];
          path.addAll(split(
              "net/minecraftforge/forge/${installProfile.version}/${installProfile.version}.jar"));

          File jarFile = File(joinAll(path));
          jarFile.createSync(recursive: true);
          jarFile.writeAsBytesSync(data);
        }
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
    if (Util.isSurrounded(mavenString, "[", "]")) {
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

  static File getLibFile(List<Library> libraries, String libraryName) {
    Artifact artifact = libraries
        .firstWhere(
            (lib) => lib.name == libraryName && lib.downloads.artifact != null)
        .downloads
        .artifact!;

    return artifact.localFile;
  }

  static handlingArgs(Map forgeMeta, String versionID, String forgeVersionID) {
    File argsFile = GameRepository.getArgsFile(
        versionID, ModLoader.vanilla, MinecraftSide.client);
    File forgeArgsFile = GameRepository.getArgsFile(
        versionID, ModLoader.forge, MinecraftSide.client,
        loaderVersion: forgeVersionID);
    Map argsObject = {};

    if (argsObject['game'] == null) {
      argsObject['game'] = [];
    }

    Version version = Util.parseMCComparableVersion(versionID);

    if (version >= Version(1, 13, 0)) {
      argsObject.addAll(json.decode(argsFile.readAsStringSync()));

      if (forgeMeta["arguments"] != null) {
        if (forgeMeta["arguments"]["game"] != null) {
          for (var i in forgeMeta["arguments"]["game"]) {
            argsObject["game"].add(i);
          }
        }
        if (forgeMeta["arguments"]["jvm"] != null) {
          for (var i in forgeMeta["arguments"]["jvm"]) {
            argsObject["jvm"].add(i);
          }
        }
      }
    } else {
      /// Forge 1.12.2
      List<String> minecraftArguments =
          forgeMeta['minecraftArguments'].toString().split(' ');
      for (var i in minecraftArguments) {
        (argsObject["game"] as List).add(i);
      }
    }

    argsObject["mainClass"] = forgeMeta["mainClass"];

    forgeArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(argsObject));
  }
}

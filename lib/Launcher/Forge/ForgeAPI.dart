import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:RPMLauncher/Launcher/APIs.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/utility.dart';

import '../../path.dart';
import '../Libraries.dart';

class ForgeAPI {
  static Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    Map body = json.decode(response.body.toString());
    return body["promos"].containsKey("${VersionID}-latest");
  }

  static Future<String> GetLoaderVersion(VersionID) async {
    final url = Uri.parse(ForgeLatestVersionAPI);
    Response response = await get(url);
    var body = json.decode(response.body.toString());
    return body["promos"]["${VersionID}-latest"];
  }

  static Future<String> GetGameLoaderVersion(VersionID) async {
    return "${VersionID}-forge-${await GetLoaderVersion(VersionID)}";
  }

  static Future<String> DownloadForgeInstaller(VersionID) async {
    String LoaderVersion = await GetGameLoaderVersion(VersionID);
    final url = Uri.parse(
        "${ForgeInstallerAPI}/${LoaderVersion.split("forge-").join("")}/forge-${LoaderVersion.split("forge-").join("")}-installer.jar");
    print(url.toString());
    var JarFile = File(join(dataHome.absolute.path, "temp", "forge-installer",
        LoaderVersion, "$LoaderVersion.jar"));
    JarFile.createSync(recursive: true);
    await http.get(url).then((response) {
      JarFile.writeAsBytesSync(response.bodyBytes);
    });
    return LoaderVersion;
  }

  static Future<Map> getVersionJson(VersionID, Archive archive) async {
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

  static Future<Map> getProfileJson(VersionID, Archive archive) async {
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

  static Future GetForgeJar(VersionID, Archive archive) async {
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

  static String GetLibraryFiles(VersionID, ClientJar) {
    var LibraryDir = Directory(
            join(dataHome.absolute.path, "versions", VersionID, "libraries"))
        .listSync(recursive: true, followLinks: true);
    var LibraryFiles = ClientJar + utility.getSeparator();
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += i.absolute.path + utility.getSeparator();
      }
    }
    return LibraryFiles;
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
    if (MavenString.startsWith("[") && MavenString.endsWith("]")) {
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

    String url =
        "$ForgeMavenUrl/$PackageGroup/$PackageName/$PackageVersion/$PackageName-$PackageVersion.$PackageExtension";

    return [
      url,
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
        split_.sublist(0, split_.length - 2).join("/")));
  }
}

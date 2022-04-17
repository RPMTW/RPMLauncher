import 'dart:convert';

import 'package:rpmlauncher/launcher/Forge/ForgeOldProfile.dart' as old_profile;
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';

import '../MinecraftClient.dart';
import 'ForgeData.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final int? spec;
  final String version;
  final Map versionJson;
  final String? path; //1.17.1 版本的Forge Path 會是 null
  final String? filePath;
  final String minecraft;
  final String? jsonPath;
  final ForgeDataList data;
  final Processors processors;
  final Libraries libraries;

  const ForgeInstallProfile({
    this.spec,
    required this.version,
    required this.versionJson,
    this.path,
    this.filePath,
    required this.minecraft,
    this.jsonPath,
    required this.data,
    required this.processors,
    required this.libraries,
  });

  factory ForgeInstallProfile.fromNewJson(Map profileJson,
          {Map? versionJson}) =>
      ForgeInstallProfile(
          spec: profileJson['spec'],
          version: profileJson['version'],
          versionJson: profileJson['VersionJson'] ?? versionJson,
          path: profileJson['path'],
          minecraft: profileJson['minecraft'],
          jsonPath: profileJson['json'],
          data: ForgeDataList.fromJson(profileJson['data']),
          processors: Processors.fromList(profileJson['processors']),
          libraries: Libraries.fromList(profileJson['libraries']));

  factory ForgeInstallProfile.fromOldJson(Map<String, dynamic> profileJson) {
    old_profile.ForgeOldProfile forgeOldProfile =
        old_profile.ForgeOldProfile.fromMap(profileJson);

    List<Library> newLibraries = [];

    String forgeMavenPath = forgeOldProfile.install.path;
    String forgeVersion = forgeOldProfile.install.version
        .replaceAll("forge ", "")
        .replaceAll("Forge ", "");

    List<String> ignoreList = [
      forgeMavenPath,
      "net.minecraft:launchwrapper:1.12",
      "lzma:lzma:0.0.1",
      "java3d:vecmath:1.5.2"
    ];

    forgeOldProfile.versionInfo.libraries.forEach((library) {
      if (!ignoreList.contains(library.name)) {
        Map result = Util.parseLibMaven(library.toMap(),
            baseUrl: library.url ?? "https://repo1.maven.org/maven2/");
        newLibraries.add(Library(
            name: library.name,
            downloads: LibraryDownloads(
                artifact: Artifact(
              url: result["Url"],
              path: result["Path"],
            ))));
      }
    });

    ///手動新增一些函式庫
    newLibraries.addAll([
      const Library(
          name: "net.minecraft:launchwrapper:1.12",
          downloads: LibraryDownloads(
              artifact: Artifact(
                  url:
                      "https://libraries.minecraft.net/net/minecraft/launchwrapper/1.12/launchwrapper-1.12.jar",
                  path:
                      "net/minecraft/launchwrapper/1.12/launchwrapper-1.12.jar",
                  sha1: "111e7bea9c968cdb3d06ef4632bf7ff0824d0f36",
                  size: 32999))),
      const Library(
          name: "lzma:lzma:0.0.1",
          downloads: LibraryDownloads(
              artifact: Artifact(
            url:
                "https://phoenixnap.dl.sourceforge.net/project/kcauldron/lzma/lzma/0.0.1/lzma-0.0.1.jar",
            path: "lzma/lzma/0.0.1/lzma-0.0.1.jar",
          ))),
      const Library(
          name: "java3d:vecmath:1.5.2",
          downloads: LibraryDownloads(
              artifact: Artifact(
                  url:
                      "https://repo1.maven.org/maven2/javax/vecmath/vecmath/1.5.2/vecmath-1.5.2.jar",
                  path: "java3d/vecmath/1.5.2/vecmath-1.5.2.jar",
                  sha1: "fd17bc3e67f909573dfc039d8e2abecf407c4e27"))),
      Library(
          name: forgeMavenPath,
          downloads: LibraryDownloads(
              artifact: Artifact(
            url: "",
            path: "net/minecraftforge/forge/$forgeVersion/$forgeVersion.jar",
          )))
    ]);

    Map forgeMeta = forgeOldProfile.versionInfo.toMap();
    forgeMeta['libraries'] = newLibraries.map((e) => e.toJson()).toList();

    return ForgeInstallProfile(
        version: forgeVersion,
        versionJson: forgeMeta,
        minecraft: forgeOldProfile.install.minecraft,
        path: forgeOldProfile.install.path,
        filePath: forgeOldProfile.install.filePath,
        data: ForgeDataList.fromJson({}),
        processors: Processors.fromList([]),
        libraries: Libraries.fromList([]));
  }

  Map<String, dynamic> toJson() => {
        'spec': spec,
        'version': version,
        'VersionJson': json.encode(versionJson),
        'path': path,
        'minecraft': minecraft,
        'jsonPath': jsonPath,
        'data': data.toList(),
        'processors': processors.toList(),
        'libraries': libraries.toList()
      };

  Future<void> getInstallerLib(MinecraftClientHandler handler) async {
    /*
    下載Forge安裝器的相關函式庫 (執行所需的依賴項)
    */
    await Future.forEach(libraries.libraries, (Library lib) async {
      Artifact? artifact = lib.downloads.artifact;
      if (artifact != null) {
        final url = artifact.url;

        if (url == "") return; //如果網址為無效則不執行下載

        installingState.downloadInfos.add(DownloadInfo(url,
            savePath: artifact.localFile.path,
            sh1Hash: artifact.sha1,
            hashCheck: true,
            description: I18n.format(
                'version.list.downloading.forge.processors.library')));
      }
    });
  }
}

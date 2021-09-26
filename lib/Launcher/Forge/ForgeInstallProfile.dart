import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/main.dart';
import 'package:path/path.dart';

import '../Libraries.dart';
import '../MinecraftClient.dart';
import 'ForgeData.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final int spec;
  final String version;
  Map VersionJson;
  final String? path; //1.17.1 版本的Forge Path 會是 null
  final String minecraft;
  final String jsonPath;
  final ForgeDatas data;
  final Processors processors;
  final Libraries libraries;

  ForgeInstallProfile({
    required this.spec,
    required this.version,
    required this.VersionJson,
    required this.path,
    required this.minecraft,
    required this.jsonPath,
    required this.data,
    required this.processors,
    required this.libraries,
  });

  factory ForgeInstallProfile.fromJson(Map _json, Map VersionJson) =>
      ForgeInstallProfile(
          spec: _json['spec'],
          version: _json['version'],
          VersionJson: _json['VersionJson'] == null
              ? VersionJson
              : json.decode(_json['VersionJson']),
          path: _json['path'],
          minecraft: _json['minecraft'],
          jsonPath: _json['json'],
          data: ForgeDatas.fromJson(_json['data']),
          processors: Processors.fromList(_json['processors']),
          libraries: Libraries.fromList(_json['libraries']));

  Map<String, dynamic> toJson() => {
        'spec': spec,
        'version': version,
        'VersionJson': json.encode(VersionJson),
        'path': path,
        'minecraft': minecraft,
        'jsonPath': jsonPath,
        'data': data.toList(),
        'processors': processors.toList(),
        'libraries': libraries.toList()
      };

  Future<void> getInstallerLib(
      MinecraftClientHandler Handler, SetState_) async {
    /*
    下載Forge安裝器的相關函式庫 (執行所需的依賴項)
    */
    await Future.forEach(libraries.libraries, (Library lib) async {
      Artifact artifact = lib.downloads.artifact;
      final url = artifact.url;
      List split_ = artifact.path.split("/");
      final FileName = split_[split_.length - 1];

      if (url == "") return; //如果網址為無效則不執行下載

      infos.add(DownloadInfo(url,
          savePath: join(
              dataHome.absolute.path,
              "temp",
              "forge-installer",
              version,
              "libraries",
              split_.sublist(0, split_.length - 1).join(Platform.pathSeparator),
              FileName),
          sh1Hash: artifact.sha1,
          hashCheck: true));
    });
  }
}

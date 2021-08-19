import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/path.dart';
import 'package:path/path.dart';

import '../Libraries.dart';
import '../MinecraftClient.dart';
import 'ForgeData.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final int spec;
  final String version;
  Map VersionJson;
  final String path;
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

  Future<void> DownloadLib(MinecraftClientHandler Handler, SetState_) async {
    /*
    下載Forge安裝器的相關函式庫 (執行所需的依賴項)
    */

    Handler.TotalTaskLength += libraries.libraries.length;

    await Future.forEach(libraries.libraries, (Library lib) async {
      Artifact artifact = lib.downloads.artifact;
      final url = artifact.url;
      List split_ = artifact.path.split("/");
      final FileName = split_[split_.length - 1];

      if (url == "")
        return SetState_(() {
          Handler.DoneTaskLength++;
        }); //如果網址為無效則不執行下載

      await Handler.DownloadFile(
          url,
          FileName,
          join(
              dataHome.absolute.path,
              "temp",
              "forge-installer",
              version,
              "libraries",
              split_
                  .sublist(0, split_.length - 1)
                  .join(Platform.pathSeparator)),
          artifact.sha1,
          SetState_);
    });
  }
}

import 'dart:convert';

import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

import '../MinecraftClient.dart';
import 'ForgeData.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final int spec;
  final String version;
  Map versionJson;
  final String? path; //1.17.1 版本的Forge Path 會是 null
  final String minecraft;
  final String jsonPath;
  final ForgeDataList data;
  final Processors processors;
  final Libraries libraries;

  ForgeInstallProfile({
    required this.spec,
    required this.version,
    required this.versionJson,
    required this.path,
    required this.minecraft,
    required this.jsonPath,
    required this.data,
    required this.processors,
    required this.libraries,
  });

  factory ForgeInstallProfile.fromJson(Map _json, Map versionJson) =>
      ForgeInstallProfile(
          spec: _json['spec'],
          version: _json['version'],
          versionJson: _json['VersionJson'] == null
              ? versionJson
              : json.decode(_json['VersionJson']),
          path: _json['path'],
          minecraft: _json['minecraft'],
          jsonPath: _json['json'],
          data: ForgeDataList.fromJson(_json['data']),
          processors: Processors.fromList(_json['processors']),
          libraries: Libraries.fromList(_json['libraries']));

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

        infos.add(DownloadInfo(url,
            savePath: artifact.localFile.path,
            sh1Hash: artifact.sha1,
            hashCheck: true,
            description: I18n.format(
                'version.list.downloading.forge.processors.library')));
      }
    });
  }
}

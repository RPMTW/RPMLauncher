import 'dart:io';

import 'package:RPMLauncher/path.dart';
import 'package:path/path.dart';

import '../Libraries.dart';
import '../MinecraftClient.dart';
import 'ForgeData.dart';
import 'Processors.dart';

class ForgeInstallProfile {
  final String spec;
  final String version;
  final String path;
  final String minecraft;
  final String jsonPath;
  final ForgeDatas data;
  final Processors processors;
  final Libraries libraries;

  const ForgeInstallProfile({
    required this.spec,
    required this.version,
    required this.path,
    required this.minecraft,
    required this.jsonPath,
    required this.data,
    required this.processors,
    required this.libraries,
  });

  factory ForgeInstallProfile.fromJson(Map json) => ForgeInstallProfile(
      spec: json['spec'],
      version: json['version'],
      path: json['path'],
      minecraft: json['minecraft'],
      jsonPath: json['json'],
      data: json['data'].keys,
      processors: Processors.fromList(json['processors']),
      libraries: Libraries.fromList(json['libraries']));

  Map<String, dynamic> toJson() => {
        'spec': spec,
        'version': version,
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

    Handler.DownloadTotalFileLength += libraries.libraries.length;
    
    libraries.libraries.forEach((lib) {
      Artifact artifact = lib.downloads.artifact;
      final url = artifact.url;
      List split_ = artifact.path.split("/");
      final FileName = split_[split_.length - 1];
      Handler.DownloadFile(
          url,
          FileName,
          join(dataHome.absolute.path, "temp", "forge-installer", version,
              "libraries", split_.sublist(0, split_.length - 2).join("/")),
          artifact.sha1,
          SetState_);
    });

  }
}

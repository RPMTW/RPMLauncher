// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

import 'Arguments.dart';

DownloadInfos infos = DownloadInfos.none();
String NowEvent = i18n.format('version.list.downloading.ready');
bool finish = false;

abstract class MinecraftClient {
  Map get Meta;

  MinecraftClientHandler get handler;

  StateSetter get setState;
}

class MinecraftClientHandler {
  void clientJar(body, VersionID) {
    infos.add(DownloadInfo(body["downloads"]["client"]["url"],
        savePath:
            join(dataHome.absolute.path, "versions", VersionID, "client.jar"),
        sh1Hash: body["downloads"]["client"]["sha1"],
        description: i18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs(body, VersionID) async {
    File ArgsFile = GameRepository.getArgsFile(VersionID, ModLoaders.Vanilla);
    await ArgsFile.create(recursive: true);
    await ArgsFile.writeAsString(
        json.encode(Arguments().GetArgsString(VersionID, body)));
  }

  Future getAssets(data, version) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = json.decode(response.body);
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "$version.json"))
      ..createSync(recursive: true);
    IndexFile.writeAsStringSync(response.body);
    for (var i in body["objects"].keys) {
      String hash = body["objects"][i]["hash"].toString();

      infos.add(DownloadInfo(
          "https://resources.download.minecraft.net/${hash.substring(0, 2)}/$hash",
          savePath: join(dataHome.absolute.path, "assets", "objects",
              hash.substring(0, 2), hash),
          sh1Hash: hash,
          hashCheck: true,
          description: i18n.format('version.list.downloading.assets')));
    }
  }

  Future getLib(body, version) async {
    Libraries.fromList(body['libraries']).libraries.forEach((lib) {
      if (lib.isnatives) {
        if (lib.downloads.classifiers != null) {
          DownloadNatives(lib.downloads.classifiers!, version);
        }

        Artifact artifact = lib.downloads.artifact;
        List split_ = artifact.path.split("/");
        infos.add(DownloadInfo(artifact.url,
            savePath: join(
                dataHome.absolute.path,
                "versions",
                version,
                "libraries",
                ModLoaders.Vanilla.fixedString,
                split_.sublist(0, split_.length - 2).join("/"),
                split_[split_.length - 1]),
            sh1Hash: artifact.sha1,
            hashCheck: true,
            description: i18n.format('version.list.downloading.library')));
      }
    });
  }

  Future DownloadNatives(Classifiers classifiers, version) async {
    List split_ = classifiers.path.split("/");
    infos.add(DownloadInfo(classifiers.url,
        savePath: join(GameRepository.getNativesDir(version).absolute.path,
            split_[split_.length - 1]),
        sh1Hash: classifiers.sha1,
        hashCheck: true,
        description: i18n.format('version.list.downloading.library'),
        onDownloaded: () async {
      await UnZip(split_[split_.length - 1],
          GameRepository.getNativesDir(version).absolute.path);
    }));
  }

  Future UnZip(fileName, dir_) async {
    File file = File(join(dir_, fileName));
    final bytes = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      final FileName = file.name;
      if (FileName.contains("META-INF")) continue;
      if (file.isFile) {
        if (FileName.endsWith(".git") || FileName.endsWith(".sha1")) continue;
        final data = file.content as List<int>;
        File(join(dir_, FileName))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(join(dir_, FileName))
          ..create(recursive: true);
      }
    }
    file.delete(recursive: true);
  }

  Future<MinecraftClientHandler> Install(Meta, VersionID, SetState) async {
    await this.getLib(Meta, VersionID);
    this.clientJar(Meta, VersionID);
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.args');
    });
    await this.getArgs(Meta, VersionID);
    await this.getAssets(Meta, VersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      SetState(() {});
    });
    return this;
  }
}

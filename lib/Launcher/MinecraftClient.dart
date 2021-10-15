// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

import 'Arguments.dart';

DownloadInfos infos = DownloadInfos.none();
String NowEvent = i18n.format('version.list.downloading.ready');
bool finish = false;

abstract class MinecraftClient {
  Map get meta => handler.meta;

  MinecraftClientHandler get handler;

  StateSetter get setState => handler.setState;

  Instance get instance => handler.instance;

  String get versionID => handler.versionID;
}

class MinecraftClientHandler {
  final Map meta;
  final String versionID;
  final StateSetter setState;
  final Instance instance;

  MinecraftClientHandler(
      {required this.meta,
      required this.versionID,
      required this.setState,
      required this.instance});

  void clientJar() {
    infos.add(DownloadInfo(meta["downloads"]["client"]["url"],
        savePath:
            join(dataHome.absolute.path, "versions", versionID, "client.jar"),
        sh1Hash: meta["downloads"]["client"]["sha1"],
        description: i18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File ArgsFile = GameRepository.getArgsFile(versionID, ModLoaders.Vanilla);
    await ArgsFile.create(recursive: true);
    await ArgsFile.writeAsString(
        json.encode(Arguments().GetArgsString(versionID, meta)));
  }

  Future getAssets() async {
    final url = Uri.parse(meta["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = json.decode(response.body);
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "$versionID.json"))
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

  Future getLib() async {
    Libraries _libs = Libraries.fromList(meta["libraries"]);
    instance.config.libraries = _libs;

    for (Library lib in _libs) {
      if (lib.isnatives) {
        if (lib.downloads.classifiers != null) {
          DownloadNatives(lib.downloads.classifiers!, versionID);
        }

        Artifact artifact = lib.downloads.artifact;
        infos.add(DownloadInfo(artifact.url,
            savePath: artifact.localFile.path,
            sh1Hash: artifact.sha1,
            hashCheck: true,
            description: i18n.format('version.list.downloading.library')));
      }
    }
  }

  void DownloadNatives(Classifiers classifiers, version) {
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
        Directory(join(dir_, FileName))..create(recursive: true);
      }
    }
    file.delete(recursive: true);
  }

  Future<MinecraftClientHandler> Install() async {
    await this.getLib();
    this.clientJar();
    setState(() {
      NowEvent = i18n.format('version.list.downloading.args');
    });
    await this.getArgs();
    await this.getAssets();
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    return this;
  }
}

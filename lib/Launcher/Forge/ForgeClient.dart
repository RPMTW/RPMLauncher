// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';

import '../APIs.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';
import 'Processors.dart';

class ForgeClient extends MinecraftClient {
  MinecraftClientHandler handler;

  String forgeVersionID;

  ForgeClient._init({required this.handler, required this.forgeVersionID});

  static Future<ForgeClient> createClient(
      {required Map meta,
      required String gameVersionID,
      required StateSetter setState,
      required String forgeVersionID,
      required Instance instance}) async {
    return await ForgeClient._init(
      handler: MinecraftClientHandler(
        versionID: gameVersionID,
        setState: setState,
        instance: instance,
        meta: meta,
      ),
      forgeVersionID: forgeVersionID,
    )._Install();
  }

  Future<ForgeInstallProfile> InstallerJarHandler(String forgeVersionID) async {
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID);
    File InstallerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", LoaderVersion, "$LoaderVersion-installer.jar"));
    final archive = ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeInstallProfile InstallProfile =
        await ForgeAPI.getProfile(versionID, archive);
    await ForgeAPI.getForgeJar(versionID, archive);
    return InstallProfile;
  }

  Future<ForgeClient> getForgeLibrary(forgeMeta) async {
    Libraries libraries = Libraries.fromList(forgeMeta["libraries"]);
    Libraries _lib = instance.config.libraries;
    _lib = Libraries(_lib
        .where((e) => !e.name
            .startsWith("org.apache.logging.log4j:log4j-")) //暫時沒想到更好的方式只好硬編碼
        .toList());
    _lib.addAll(libraries);

    instance.config.libraries = _lib;
    libraries.forEach((lib) async {
      var artifact = lib.downloads.artifact;

      if (artifact.url == "") return;

      infos.add(DownloadInfo(artifact.url,
          savePath: artifact.localFile.path,
          hashCheck: true,
          sh1Hash: artifact.sha1,
          description: i18n.format('version.list.downloading.forge.library')));
    });
    return this;
  }

  Future getForgeArgs(Map Meta) async {
    File ArgsFile = GameRepository.getArgsFile(versionID, ModLoaders.Vanilla);
    File ForgeArgsFile =
        GameRepository.getArgsFile(versionID, ModLoaders.Forge, forgeVersionID);
    Map ArgsObject = await json.decode(ArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = Meta["mainClass"];
    for (var i in Meta["arguments"]["game"]) {
      ArgsObject["game"].add(i);
    }
    for (var i in Meta["arguments"]["jvm"]) {
      ArgsObject["jvm"].add(i);
    }
    ForgeArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(ArgsObject));
  }

  Future<ForgeClient> getForgeInstaller(String forgeVersionID) async {
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID);
    final String url =
        "$ForgeMavenMainUrl/${LoaderVersion.split("forge-").join("")}/forge-${LoaderVersion.split("forge-").join("")}-installer.jar";
    infos.add(DownloadInfo(url,
        savePath: join(dataHome.absolute.path, "temp", "forge-installer",
            LoaderVersion, "$LoaderVersion-installer.jar"),
        description: i18n.format('version.list.downloading.forge.installer')));
    return this;
  }

  Future<ForgeClient> runForgeProcessors(
      ForgeInstallProfile Profile, InstanceDirName) async {
    await Future.forEach(Profile.processors.processors,
        (Processor processor) async {
      await processor.Execution(
          InstanceDirName,
          Profile.libraries.libraries,
          ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID),
          versionID,
          Profile.data);
    });
    return this;
  }

  Future<ForgeClient> _Install() async {
    infos = DownloadInfos.none();
    await this.getForgeInstaller(forgeVersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.profile');
    });
    ForgeInstallProfile InstallProfile =
        await InstallerJarHandler(forgeVersionID);
    Map ForgeMeta = InstallProfile.VersionJson;
    await handler.Install();
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.args');
    });
    await this.getForgeArgs(ForgeMeta);
    await this.getForgeLibrary(ForgeMeta);
    await InstallProfile.getInstallerLib(handler, setState);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.processors.run');
    });
    await this.runForgeProcessors(InstallProfile, instance.name);
    // setState(() {
    //   NowEvent = i18n.format('version.list.downloading.forge.moving');
    // });
    // await this.MovingLibrary();
    return this;
  }
}

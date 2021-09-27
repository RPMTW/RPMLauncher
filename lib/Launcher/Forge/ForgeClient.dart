// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/Libraries.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';

import '../APIs.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';
import 'Processors.dart';

class ForgeClient implements MinecraftClient {
  Map Meta;
  MinecraftClientHandler handler;
  String gameVersionID;
  String forgeVersionID;
  String InstanceDirName;
  StateSetter setState;

  ForgeClient._init(
      {required this.Meta,
      required this.handler,
      required this.gameVersionID,
      required this.setState,
      required this.forgeVersionID,
      required this.InstanceDirName});

  static Future<ForgeClient> createClient(
      {required Meta,
      required gameVersionID,
      required setState,
      required forgeVersionID,
      required InstanceDirName}) async {
    return await ForgeClient._init(
            handler: MinecraftClientHandler(),
            setState: setState,
            Meta: Meta,
            gameVersionID: gameVersionID,
            forgeVersionID: forgeVersionID,
            InstanceDirName: InstanceDirName)
        ._Install();
  }

  Future<ForgeInstallProfile> InstallerJarHandler(VersionID) async {
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(VersionID, forgeVersionID);
    File InstallerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", LoaderVersion, "$LoaderVersion-installer.jar"));
    final archive =
        ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeInstallProfile InstallProfile =
        await ForgeAPI.getProfile(VersionID, archive);
    await ForgeAPI.getForgeJar(VersionID, archive);
    return InstallProfile;
  }

  Future<ForgeClient> getForgeLibrary(Meta, VersionID, SetState) async {
    List<Library> libraries = Libraries.fromList(Meta["libraries"]).libraries;
    libraries.forEach((lib) async {
      var artifact = lib.downloads.artifact;
      List split_ = artifact.path.toString().split("/");

      if (artifact.url == "") return;

      infos.add(DownloadInfo(artifact.url,
          savePath: join(
              dataHome.absolute.path,
              "versions",
              VersionID,
              "libraries",
              split_.sublist(0, split_.length - 2).join("/"),
              split_[split_.length - 1]),
          hashCheck: true,
          sh1Hash: artifact.sha1,
          description: i18n.format('version.list.downloading.forge.library')));
    });
    return this;
  }

  Future getForgeArgs(Map Meta, String VersionID, String LoaderVersion) async {
    File ArgsFile = GameRepository.getArgsFile(VersionID, ModLoaders.Vanilla);
    File ForgeArgsFile =
        GameRepository.getArgsFile(VersionID, ModLoaders.Forge, LoaderVersion);
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

  Future<ForgeClient> getForgeInstaller(VersionID, forgeVersionID) async {
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(VersionID, forgeVersionID);
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
          ForgeAPI.getGameLoaderVersion(gameVersionID, forgeVersionID),
          gameVersionID,
          Profile.data);
    });
    return this;
  }

  Future<ForgeClient> MovingLibrary() async {
    Directory ForgeClientDir = Directory(join(
        GameRepository.getLibraryRootDir(gameVersionID).absolute.path,
        "net",
        "minecraft",
        "client"));
    Directory ForgeDir = Directory(join(
        GameRepository.getLibraryRootDir(gameVersionID).absolute.path,
        "net",
        "minecraftforge",
        "forge"));

    if (ForgeClientDir.existsSync() && ForgeDir.existsSync()) {
      utility.copyDirectory(
          ForgeClientDir,
          Directory(join(
              GameRepository.getVersionsDir(gameVersionID).absolute.path,
              "net",
              "minecraft",
              "client")));
      utility.copyDirectory(
          ForgeDir,
          Directory(join(
              GameRepository.getVersionsDir(gameVersionID).absolute.path,
              "net",
              "minecraftforge",
              "forge")));
    } else {
      throw Exception("Forge Client directory not found");
    }
    return this;
  }

  Future<ForgeClient> _Install() async {
    infos = DownloadInfos.none();
    await this.getForgeInstaller(gameVersionID, forgeVersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.profile');
    });
    ForgeInstallProfile InstallProfile =
        await InstallerJarHandler(gameVersionID);
    Map ForgeMeta = InstallProfile.VersionJson;
    await handler.Install(Meta, gameVersionID, setState);
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.args');
    });
    await this.getForgeArgs(ForgeMeta, gameVersionID, forgeVersionID);
    await this.getForgeLibrary(ForgeMeta, gameVersionID, setState);
    await InstallProfile.getInstallerLib(handler, setState);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.processors.run');
    });
    await this.runForgeProcessors(InstallProfile, InstanceDirName);
    setState(() {
      NowEvent = i18n.format('version.list.downloading.forge.moving');
    });
    await this.MovingLibrary();
    finish = true;
    return this;
  }
}

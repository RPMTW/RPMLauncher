import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Utility/Data.dart';
import 'package:flutter/material.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/Dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';

import '../APIs.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';
import 'Processors.dart';

enum ForgeClientState { successful, unknownProfile, unSupportedVersion }

extension ForgeClientStateExtension on ForgeClientState {
  Future<void> handlerState(
      BuildContext context, StateSetter setState, Instance instance,
      {bool notFinal = false,
      Future<void> Function(Instance)? onSuccessful}) async {
    switch (this) {
      case ForgeClientState.successful:
        if (!notFinal) {
          nowEvent = I18n.format('version.list.downloading.handling');
          setState(() {});
          await onSuccessful?.call(instance);
          finish = true;
          setState(() {});
        }
        break;
      case ForgeClientState.unknownProfile:
        navigator.pushNamed(HomePage.route);
        await Future.delayed(Duration.zero, () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                  title: I18nText.errorInfoText(),
                  content:
                      I18nText("version.list.downloading.forge.profile.error"),
                  actions: [OkClose()]));
        });
        break;
      case ForgeClientState.unSupportedVersion:
        navigator.pushNamed(HomePage.route);
        await Future.delayed(Duration.zero, () {
          showDialog(
              context: context,
              builder: (context) => UnSupportedForgeVersion(
                  gameVersion: instance.config.version));
        });
        break;
    }
  }
}

class ForgeClient extends MinecraftClient {
  @override
  MinecraftClientHandler handler;

  String forgeVersionID;

  ForgeClient._init({required this.handler, required this.forgeVersionID});

  static Future<ForgeClientState> createClient(
      {required MinecraftMeta meta,
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
    )._install();
  }

  Future<ForgeInstallProfile?> installerJarHandler(
      String forgeVersionID) async {
    String loaderVersion =
        ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID);
    File installerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", loaderVersion, "$loaderVersion-installer.jar"));
    ForgeInstallProfile? installProfile;
    try {
      final archive = ZipDecoder().decodeBytes(installerFile.readAsBytesSync());

      installProfile = await ForgeAPI.getProfile(versionID, archive);

      if (installProfile == null) return null;

      /// Minecraft Forge 1.17.1+ no need to extract FML from jar
      if (instance.config.comparableVersion < Version(1, 17, 1)) {
        await ForgeAPI.getForgeJar(versionID, archive, installProfile);
      }
    } on FormatException {
    } on FileSystemException {}

    return installProfile;
  }

  Future<ForgeClient> getForgeLibrary(forgeMeta) async {
    Libraries libraries = Libraries.fromList(forgeMeta["libraries"]);
    Libraries _lib = instance.config.libraries;

    _lib.addAll(libraries);

    instance.config.libraries = _lib;
    libraries.forEach((lib) async {
      Artifact? artifact = lib.downloads.artifact;
      if (artifact != null) {
        if (artifact.url == "") return;

        infos.add(DownloadInfo(artifact.url,
            savePath: artifact.localFile.path,
            hashCheck: true,
            sh1Hash: artifact.sha1,
            description:
                I18n.format('version.list.downloading.forge.library')));
      }
    });
    return this;
  }

  Future getForgeArgs(Map meta) async {
    File argsFile = GameRepository.getArgsFile(versionID, ModLoader.vanilla);
    File forgeArgsFile = GameRepository.getArgsFile(versionID, ModLoader.forge,
        loaderVersion: forgeVersionID);
    Map argsObject = {};

    if (argsObject['game'] == null) {
      argsObject['game'] = [];
    }

    if (instance.config.comparableVersion >= Version(1, 13, 0)) {
      argsObject.addAll(json.decode(argsFile.readAsStringSync()));
      if (meta["arguments"]["game"] != null) {
        for (var i in meta["arguments"]["game"]) {
          argsObject["game"].add(i);
        }
      }
      if (meta["arguments"]["jvm"] != null) {
        for (var i in meta["arguments"]["jvm"]) {
          argsObject["jvm"].add(i);
        }
      }
    } else {
      /// Forge 1.12.2
      List<String> minecraftArguments =
          meta['minecraftArguments'].toString().split(' ');
      for (var i in minecraftArguments) {
        (argsObject["game"] as List).add(i);
      }
    }

    argsObject["mainClass"] = meta["mainClass"];

    forgeArgsFile
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(argsObject));
  }

  Future<ForgeClient> getForgeInstaller(String forgeVersionID) async {
    String loaderVersion =
        ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID);

    final String url =
        "$forgeMavenMainUrl/${loaderVersion.split("forge-").join("")}/forge-${loaderVersion.split("forge-").join("")}-installer.jar";
    infos.add(DownloadInfo(url,
        savePath: join(dataHome.absolute.path, "temp", "forge-installer",
            loaderVersion, "$loaderVersion-installer.jar"),
        description: I18n.format('version.list.downloading.forge.installer')));
    return this;
  }

  Future<ForgeClient> runForgeProcessors(
      ForgeInstallProfile profile, InstanceConfig instanceConfig) async {
    await Future.forEach(profile.processors.processors,
        (Processor processor) async {
      await processor.execution(
          instanceConfig,
          profile.libraries.libraries,
          ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID),
          versionID,
          profile.data);
    });
    return this;
  }

  Future<ForgeClientState> _install() async {
    if (instance.config.comparableVersion < Version(1, 7, 0)) {
      return ForgeClientState.unSupportedVersion;
    }
    infos = DownloadInfos.empty();
    await getForgeInstaller(forgeVersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      nowEvent = I18n.format('version.list.downloading.forge.profile');
    });
    ForgeInstallProfile? installProfile =
        await installerJarHandler(forgeVersionID);

    if (installProfile == null) {
      return ForgeClientState.unknownProfile;
    }

    Map forgeMeta = installProfile.versionJson;
    await handler.install();
    setState(() {
      nowEvent = I18n.format('version.list.downloading.forge.args');
    });
    await getForgeArgs(forgeMeta);
    await getForgeLibrary(forgeMeta);
    await installProfile.getInstallerLib(handler);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      setState(() {});
    });
    setState(() {
      nowEvent = I18n.format('version.list.downloading.forge.processors.run');
    });
    await runForgeProcessors(installProfile, instance.config);

    return ForgeClientState.successful;
  }
}

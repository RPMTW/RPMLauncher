import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/main.dart';

import '../APIs.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';
import 'Processors.dart';

enum ForgeClientState { successful, failed, unknown, unknownProfile }

extension ForgeClientStateExtension on ForgeClientState {
  Future<void> handlerState(BuildContext context, StateSetter setState,
      {bool notFinal = false}) async {
    switch (this) {
      case ForgeClientState.successful:
        if (!notFinal) {
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
      case ForgeClientState.failed:
        // TODO: Handle this case.
        break;
      case ForgeClientState.unknown:
        // TODO: Handle this case.
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
    final archive = ZipDecoder().decodeBytes(installerFile.readAsBytesSync());
    ForgeInstallProfile? installProfile =
        await ForgeAPI.getProfile(versionID, archive);
    await ForgeAPI.getForgeJar(versionID, archive);
    return installProfile;
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
    File argsFile = GameRepository.getArgsFile(versionID, ModLoaders.vanilla);
    File forgeArgsFile = GameRepository.getArgsFile(versionID, ModLoaders.forge,
        loaderVersion: forgeVersionID);
    Map argsObject = await json.decode(argsFile.readAsStringSync());
    argsObject["mainClass"] = meta["mainClass"];
    for (var i in meta["arguments"]["game"]) {
      argsObject["game"].add(i);
    }
    for (var i in meta["arguments"]["jvm"]) {
      argsObject["jvm"].add(i);
    }
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

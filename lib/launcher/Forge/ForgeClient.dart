import 'dart:async';
import 'dart:io';

import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:flutter/material.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeAPI.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/IO/download_info.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/widget/dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';

import '../apis.dart';
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
          installingState.nowEvent =
              I18n.format('version.list.downloading.handling');
          setState(() {});
          await onSuccessful?.call(instance);
          installingState.finish = true;
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
                  actions: const [OkClose()]));
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
    Libraries forgeLibraries = Libraries.fromList(forgeMeta["libraries"]);
    Libraries libraries = instance.config.libraries;

    libraries.addAll(forgeLibraries);

    instance.config.libraries = libraries;
    forgeLibraries.forEach((lib) async {
      Artifact? artifact = lib.downloads.artifact;
      if (artifact != null) {
        if (artifact.url == "") return;

        installingState.downloadInfos.add(DownloadInfo(artifact.url,
            savePath: artifact.localFile.path,
            hashCheck: true,
            sh1Hash: artifact.sha1,
            description:
                I18n.format('version.list.downloading.forge.library')));
      }
    });
    return this;
  }

  Future<ForgeClient> getForgeInstaller(String forgeVersionID) async {
    String loaderVersion =
        ForgeAPI.getGameLoaderVersion(versionID, forgeVersionID);

    final String url =
        "$forgeMavenMainUrl/${loaderVersion.split("forge-").join("")}/forge-${loaderVersion.split("forge-").join("")}-installer.jar";
    installingState.downloadInfos.add(DownloadInfo(url,
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
          profile.libraries,
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
    installingState.downloadInfos = DownloadInfos.empty();
    await getForgeInstaller(forgeVersionID);
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      setState(() {});
    });
    setState(() {
      installingState.nowEvent =
          I18n.format('version.list.downloading.forge.profile');
    });
    ForgeInstallProfile? installProfile =
        await installerJarHandler(forgeVersionID);

    if (installProfile == null) {
      return ForgeClientState.unknownProfile;
    }

    Map forgeMeta = installProfile.versionJson;
    await handler.install();
    setState(() {
      installingState.nowEvent =
          I18n.format('version.list.downloading.forge.args');
    });
    await ForgeAPI.handlingArgs(forgeMeta, versionID, forgeVersionID);
    await getForgeLibrary(forgeMeta);
    await installProfile.getInstallerLib(handler);
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (progress) {
      setState(() {});
    });
    setState(() {
      installingState.nowEvent =
          I18n.format('version.list.downloading.forge.processors.run');
    });
    await runForgeProcessors(installProfile, instance.config);

    return ForgeClientState.successful;
  }
}

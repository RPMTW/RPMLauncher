import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:http/http.dart' as http;
import 'package:RPMLauncher/Launcher/Libraries.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';

import '../../path.dart';
import '../APIs.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';

class ForgeClient implements MinecraftClient {
  Map Meta;
  MinecraftClientHandler handler;
  String gameVersionID;
  String forgeVersionID;
  var setState;

  ForgeClient._init(
      {required this.Meta,
      required this.handler,
      required this.gameVersionID,
      required this.setState,
      required this.forgeVersionID}) {}

  static Future<ForgeClient> createClient(
      {required Map Meta,
      required String VersionID,
      required setState,
      required forgeVersionID}) async {
    return await new ForgeClient._init(
            handler: await new MinecraftClientHandler(),
            setState: setState,
            Meta: Meta,
            gameVersionID: VersionID,
            forgeVersionID: forgeVersionID)
        ._Install();
  }

  Future<ForgeInstallProfile> InstallerJarHandler(VersionID) async {
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(VersionID, forgeVersionID);
    File InstallerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", LoaderVersion, "$LoaderVersion-installer.jar"));
    final archive =
        await ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeInstallProfile InstallProfile =
        await ForgeAPI.getProfile(VersionID, archive);
    ForgeAPI.GetForgeJar(VersionID, archive);
    return InstallProfile;
  }

  Future<ForgeClient> DownloadForgeLibrary(Meta, VersionID, SetState_) async {
    List<Library> libraries = Libraries.fromList(Meta["libraries"]).libraries;
    libraries.forEach((lib) async {
      var artifact = lib.downloads.artifact;
      List split_ = artifact.path.toString().split("/");

      if (artifact.url == "") return;

      handler.TotalTaskLength++;
      handler.DownloadFile(
          artifact.url,
          split_[split_.length - 1],
          join(dataHome.absolute.path, "versions", VersionID, "libraries",
              split_.sublist(0, split_.length - 2).join("/")),
          artifact.sha1,
          SetState_);
    });
    return this;
  }

  Future GetForgeArgs(Meta, VersionID) async {
    handler.TotalTaskLength++;
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    File NewArgsFile = File(join(dataHome.absolute.path, "versions", VersionID,
        "${ModLoader().Forge}_args.json"));
    Map ArgsObject = await json.decode(ArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = Meta["mainClass"];
    for (var i in Meta["arguments"]["game"]) {
      ArgsObject["game"].add(i);
    }
    for (var i in Meta["arguments"]["jvm"]) {
      ArgsObject["jvm"].add(i);
    }
    NewArgsFile.writeAsStringSync(json.encode(ArgsObject));
    handler.DoneTaskLength++;
  }

  Future DownloadForgeInstaller(VersionID, forgeVersionID) async {
    handler.TotalTaskLength++;
    String LoaderVersion =
        ForgeAPI.getGameLoaderVersion(VersionID, forgeVersionID);
    final String url =
        "${ForgeMavenMainUrl}/${LoaderVersion.split("forge-").join("")}/forge-${LoaderVersion.split("forge-").join("")}-installer.jar";
    await handler.DownloadFile(
        url,
        "${LoaderVersion}-installer.jar",
        join(dataHome.absolute.path, "temp", "forge-installer", LoaderVersion),
        '',
        setState);
  }

  Future<ForgeClient> _Install() async {
    await this.DownloadForgeInstaller(gameVersionID, forgeVersionID);

    ForgeInstallProfile InstallProfile =
        await InstallerJarHandler(gameVersionID);

    await InstallProfile.DownloadLib(handler, setState);
    Map ForgeMeta = InstallProfile.VersionJson;
    await handler.Install(Meta, gameVersionID, setState);
    await this.GetForgeArgs(ForgeMeta, gameVersionID);
    await this.DownloadForgeLibrary(ForgeMeta, gameVersionID, setState);
    return this;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:http/http.dart' as http;
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/Libraries.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../../path.dart';
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
  var setState;

  ForgeClient._init(
      {required this.Meta,
      required this.handler,
      required this.gameVersionID,
      required this.setState,
      required this.forgeVersionID,
      required this.InstanceDirName}) {}

  static Future<ForgeClient> createClient(
      {required Meta,
      required gameVersionID,
      required setState,
      required forgeVersionID,
      required InstanceDirName}) async {
    return await new ForgeClient._init(
            handler: await new MinecraftClientHandler(),
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
        await ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeInstallProfile InstallProfile =
        await ForgeAPI.getProfile(VersionID, archive);
    await ForgeAPI.GetForgeJar(VersionID, archive);
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

  Future<ForgeClient> DownloadForgeInstaller(VersionID, forgeVersionID) async {
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
    return this;
  }

  Future<ForgeClient> RunForgeProcessors(
      ForgeInstallProfile Profile, InstanceDirName) async {
    await Future.forEach(Profile.processors.processors,
        (Processor processor) async {
      handler.TotalTaskLength++;
      await processor.Execution(
          InstanceDirName,
          Profile.libraries.libraries,
          ForgeAPI.getGameLoaderVersion(gameVersionID, forgeVersionID),
          gameVersionID,
          Profile.data);
      handler.DoneTaskLength++;
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
      throw new Exception("Forge Client directory not found");
    }
    return this;
  }

  Future<ForgeClient> _Install() async {
    setState(() {
      NowEvent = "正在下載Forge安裝器";
    });
    await this.DownloadForgeInstaller(gameVersionID, forgeVersionID);
    setState(() {
      NowEvent = "正在處理Forge配置檔案";
    });
    ForgeInstallProfile InstallProfile =
        await InstallerJarHandler(gameVersionID);
    Map ForgeMeta = InstallProfile.VersionJson;
    await handler.Install(Meta, gameVersionID, setState);
    setState(() {
      NowEvent = "正在處理Forge啟動參數";
    });
    await this.GetForgeArgs(ForgeMeta, gameVersionID);
    setState(() {
      NowEvent = "正在下載Forge函式庫檔案";
    });
    await this.DownloadForgeLibrary(ForgeMeta, gameVersionID, setState);
    setState(() {
      NowEvent = "正在下載Forge處理器函式庫檔案";
    });
    await InstallProfile.DownloadLib(handler, setState);
    setState(() {
      NowEvent = "正在執行Forge處理器腳本";
    });
    await this.RunForgeProcessors(InstallProfile, InstanceDirName);
    setState(() {
      NowEvent = "正在移動函式庫位置";
    });
    await this.MovingLibrary();
    finish = true;
    return this;
  }
}

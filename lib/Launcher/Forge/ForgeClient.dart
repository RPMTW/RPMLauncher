import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:RPMLauncher/Launcher/Libraries.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';

import '../../path.dart';
import '../MinecraftClient.dart';
import 'ForgeInstallProfile.dart';

class ForgeClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  var SetState;

  static var ForgeMeta;

  ForgeClient._init(
      {required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState,
      required InstallProfile
      
      }) {
        
      }

  static Future<ForgeClient> createClient(
      {required Map Meta, required String VersionID, required setState}) async {
    String ForgeVersionID = await ForgeAPI.DownloadForgeInstaller(VersionID);
    ForgeInstallProfile InstallProfile =
        await InstallerJarHandler(VersionID, ForgeVersionID);

    return await new ForgeClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            Meta: Meta,
            VersionID: VersionID,
            InstallProfile:InstallProfile
            )
        ._Install(Meta, ForgeMeta, VersionID, setState);
  }

  static Future<ForgeInstallProfile> InstallerJarHandler(
      VersionID, ForgeVersionID) async {
    File InstallerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", ForgeVersionID, "$ForgeVersionID.jar"));
    final archive =
        await ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeMeta = await ForgeAPI.getVersionJson(VersionID, archive);
    ForgeAPI.GetForgeJar(VersionID, archive);

    ForgeInstallProfile InstallProfile = ForgeInstallProfile.fromJson(
        await ForgeAPI.getVersionJson(VersionID, archive));

    return InstallProfile;
  }

  Future<ForgeClient> DownloadForgeLibrary(Meta, VersionID, SetState_) async {
    List<Library> libraries = Libraries.fromList(Meta["libraries"]).libraries;
    libraries.forEach((lib) async {
      var artifact = lib.downloads.artifact;
      List split_ = artifact.path.toString().split("/");

      if (lib.name.toString().startsWith("net.minecraftforge:forge:")) {
        //處理一些例外錯誤
        return;
      }

      handler.DownloadTotalFileLength++;
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
  }

  Future<ForgeClient> _Install(Meta, ForgeMeta, VersionID, SetState) async {
    await handler.Install(Meta, VersionID, SetState);
    await this.GetForgeArgs(ForgeMeta, VersionID);
    await this.DownloadForgeLibrary(ForgeMeta, VersionID, SetState);
    return this;
  }
}

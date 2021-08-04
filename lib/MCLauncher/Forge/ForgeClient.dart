import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:RPMLauncher/MCLauncher/Forge/ForgeAPI.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class ForgeClient implements MinecraftClient {
  Directory InstanceDir;

  Map Meta;

  MinecraftClientHandler handler;

  var SetState;

  static var ForgeMeta;

  ForgeClient._init(
      {required this.InstanceDir,
      required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<ForgeClient> createClient(
      {required Directory InstanceDir,
      required Map Meta,
      required String VersionID,
      required setState}) async {
    var ForgeID = await ForgeAPI().DownloadForgeInstaller(VersionID);
    await InstallerJarHandler(VersionID, ForgeID);

    return await new ForgeClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            InstanceDir: InstanceDir,
        Meta: Meta,
            VersionID: VersionID)
        ._Install(Meta, ForgeMeta, VersionID, InstanceDir, setState);
  }

  static Future InstallerJarHandler(VersionID, ForgeID) async {
    File InstallerFile = File(join(
        Directory.systemTemp.absolute.path, "forge-installer", "$ForgeID.jar"));
    final archive =
        await ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
    ForgeMeta = await ForgeAPI().GetVersionJson(VersionID, archive);
    ForgeAPI().GetForgeJar(VersionID, archive);
  }

  Future<ForgeClient> DownloadForgeLibrary(Meta, VersionID, SetState_) async {
    Meta["libraries"].forEach((lib) async {
      if (lib["downloads"].keys.contains("artifact")) {
        var artifact = lib["downloads"]["artifact"];
        List split_ = artifact["path"].toString().split("/");

        if (lib["name"].toString().startsWith("net.minecraftforge:forge:")) {
          //處理一些例外錯誤
          return;
        }
        handler.DownloadTotalFileLength++;
        handler.DownloadFile(
            artifact["url"],
            split_[split_.length - 1],
            join(dataHome.absolute.path, "versions", VersionID, "libraries",
                split_.sublist(0, split_.length - 2).join("/")),
            artifact["sha1"],
            SetState_);
      }
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

  Future<ForgeClient> _Install(
      Meta, ForgeMeta, VersionID, InstanceDir, SetState) async {
    await handler.Install(Meta, VersionID, InstanceDir, SetState);
    await this.GetForgeArgs(ForgeMeta, VersionID);
    await this.DownloadForgeLibrary(ForgeMeta, VersionID, SetState);
    return this;
  }
}

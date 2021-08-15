import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:path/path.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class FabricClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  var setState;

  FabricClient._init(
      {required this.Meta,
      required this.handler,
      required String VersionID,
      required SetState,
      required String LoaderVersion}) {}

  static Future<FabricClient> createClient(
      {required Map Meta,
      required String VersionID,
      required setState,
      required String LoaderVersion}) async {
    var bodyString = await FabricAPI().GetProfileJson(VersionID, LoaderVersion);
    Map<String, dynamic> body = await json.decode(bodyString);
    var FabricMeta = body;
    return await new FabricClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            Meta: Meta,
            VersionID: VersionID,
            LoaderVersion: LoaderVersion)
        ._Ready(Meta, FabricMeta, VersionID, setState);
  }

  Future<FabricClient> DownloadFabricLibrary(Meta, VersionID, SetState_) async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    Meta["libraries"].forEach((lib) async {
      handler.TotalTaskLength++;
      var Result = utility.ParseLibMaven(lib);
      handler.DownloadFile(
          Result["Url"],
          Result["Filename"],
          join(dataHome.absolute.path, "versions", VersionID, "libraries"),
          "sha1",
          SetState_);
    });
    return this;
  }

  Future GetFabricArgs(Meta, VersionID) async {
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    File NewArgsFile = File(join(dataHome.absolute.path, "versions", VersionID,
        "${ModLoader().Fabric}_args.json"));
    Map ArgsObject = await json.decode(ArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = Meta["mainClass"];
    NewArgsFile.writeAsStringSync(json.encode(ArgsObject));
  }

  Future<FabricClient> _Ready(Meta, FabricMeta, VersionID, SetState) async {
    await handler.Install(Meta, VersionID, SetState);
    await this.GetFabricArgs(FabricMeta, VersionID);
    await this.DownloadFabricLibrary(FabricMeta, VersionID, SetState);
    return this;
  }
}

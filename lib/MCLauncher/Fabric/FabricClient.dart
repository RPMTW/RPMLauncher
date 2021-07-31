import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class FabricClient implements MinecraftClient {
  Directory InstanceDir;

  String VersionMetaUrl;

  MinecraftClientHandler handler;

  var SetState;

  FabricClient._init(
      {required this.InstanceDir,
      required this.VersionMetaUrl,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<FabricClient> createClient(
      {required Directory InstanceDir,
      required String VersionMetaUrl,
      required String VersionID,
      required setState}) async {
    var bodyString = await FabricAPI().GetProfileJson(VersionID);
    Map<String, dynamic> body = await json.decode(bodyString);
    var FabricMeta = body;
    return await new FabricClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            InstanceDir: InstanceDir,
            VersionMetaUrl: VersionMetaUrl,
            VersionID: VersionID)
        ._Ready(VersionMetaUrl, FabricMeta, VersionID, InstanceDir, setState);
  }

  Future<FabricClient> DownloadFabricLibrary(Meta, VersionID, SetState_) async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */
    Meta["libraries"].forEach((lib) async {
      handler.DownloadTotalFileLength++;
      var Result = utility().ParseLibMaven(lib);
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
    File ArgsFile = File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    File NewArgsFile = File(join(dataHome.absolute.path, "versions", VersionID, "${ModLoader().Fabric}_args.json"));
    Map ArgsObject = await json.decode(ArgsFile.readAsStringSync());
    ArgsObject["mainClass"] = Meta["mainClass"];
    NewArgsFile.writeAsStringSync(json.encode(ArgsObject));
  }

  Future<FabricClient> _Ready(
      VersionMetaUrl, FabricMeta, VersionID, InstanceDir, SetState) async {
    await handler.Install(VersionMetaUrl, VersionID, InstanceDir, SetState);
    await this.GetFabricArgs(FabricMeta, VersionID);
    await this.DownloadFabricLibrary(FabricMeta, VersionID, SetState);
    return this;
  }
}

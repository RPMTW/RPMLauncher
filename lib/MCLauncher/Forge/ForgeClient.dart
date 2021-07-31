import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class ForgeClient implements MinecraftClient {
  Directory InstanceDir;

  String VersionMetaUrl;

  MinecraftClientHandler handler;

  var SetState;

  ForgeClient._init(
      {required this.InstanceDir,
      required this.VersionMetaUrl,
      required this.handler,
      required String VersionID,
      required SetState}) {}

  static Future<ForgeClient> createClient(
      {required Directory InstanceDir,
      required String VersionMetaUrl,
      required String VersionID,
      required setState}) async {
    var bodyString = await ForgeAPI().GetProfileJson(VersionID);
    Map<String, dynamic> body = await json.decode(bodyString);
    var ForgeMeta = body;
    return await new ForgeClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            InstanceDir: InstanceDir,
            VersionMetaUrl: VersionMetaUrl,
            VersionID: VersionID)
        ._Ready(VersionMetaUrl, ForgeMeta, VersionID, InstanceDir, setState);
  }

  Future<ForgeClient> DownloadForgeLibrary(Meta, VersionID, SetState_) async {
    Meta["libraries"].forEach((lib) async {
      if (lib["downloads"].keys.contains("artifact")) {
        var artifact = lib["downloads"]["artifact"];
        handler.DownloadTotalFileLength++;
        List split_ = artifact["path"].toString().split("/");
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
    for (var i in Meta["arguments"]["game"]){
      ArgsObject["game"].add(i);
    }
    for (var i in Meta["arguments"]["jvm"]){
      print(i);
      ArgsObject["jvm"].add(i.replaceAll("\${library_directory}",
          join(dataHome.absolute.path, "versions", VersionID, "libraries"))
          .replaceAll("\${classpath_separator}", ","));
    }
    print(ArgsObject);
    NewArgsFile.writeAsStringSync(json.encode(ArgsObject));
  }

  Future<ForgeClient> _Ready(
      VersionMetaUrl, ForgeMeta, VersionID, InstanceDir, SetState) async {
    // await handler.Install(VersionMetaUrl, VersionID, InstanceDir, SetState);
    await this.GetForgeArgs(ForgeMeta, VersionID);
    // await this.DownloadForgeLibrary(ForgeMeta, VersionID, SetState);
    return this;
  }
}

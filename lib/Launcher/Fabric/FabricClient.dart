import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Model/DownloadInfo.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

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
    setState(() {
      NowEvent = "正在解析Fabric數據資料";
    });
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

  Future<FabricClient> getFabricLibrary(Meta, VersionID) async {
    /*    PackageName example: (abc.ab.com)
    name: PackageName:JarName:JarVersion
    url: https://maven.fabricmc.net
     */

    Meta["libraries"].forEach((lib) async {
      var Result = utility.ParseLibMaven(lib);

      infos.add(DownloadInfo(Result["Url"],
          savePath: join(dataHome.absolute.path, "versions", VersionID,
              "libraries", Result["Filename"]),
          description: i18n.format('version.list.downloading.fabric.library')));
    });
    return this;
  }

  Future getFabricArgs(Meta, VersionID) async {
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
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.fabric.args');
    });
    await this.getFabricArgs(FabricMeta, VersionID);
    await this.getFabricLibrary(FabricMeta, VersionID);
    await infos.downloadAll(onReceiveProgress: (_progress) {
      SetState(() {});
    });
    finish = true;
    return this;
  }
}

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

class FTBModPackClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  var setState;

  FTBModPackClient._init({
    required this.Meta,
    required Map VersionInfo,
    required this.handler,
    required Map PackData,
    required String InstanceDirName,
    required context,
    required SetState,
  }) {}

  static Future<FTBModPackClient> createClient({
    required Map Meta,
    required Map VersionInfo,
    required Map PackData,
    required String InstanceDirName,
    required context,
    required SetState,
  }) async {
    return await new FTBModPackClient._init(
      handler: await new MinecraftClientHandler(),
      Meta: Meta,
      VersionInfo: VersionInfo,
      PackData: PackData,
      InstanceDirName: InstanceDirName,
      context: context,
      SetState: SetState,
    )._Ready(Meta, VersionInfo, PackData, InstanceDirName, context, SetState);
  }

  Future<void> DownloadFiles(
      Map VersionInfo, InstanceDirName, SetState_) async {
    handler.TotalTaskLength += VersionInfo["files"].length;
    for (Map file in VersionInfo["files"]) {
      if (!file["serveronly"] == true) return; //如果非必要檔案則不下載 (目前RWL僅支援客戶端安裝)

      final String Filepath = file['path'].toString().replaceFirst('./',
          InstanceRepository.getInstanceDir(InstanceDirName).absolute.path);
      final String FileName = file["name"];

      handler.DownloadFile(
              file["url"], FileName, Filepath, file['sha1'], SetState_)
          .timeout(new Duration(milliseconds: 300), onTimeout: () {});
      ;
    }
  }

  Future<FTBModPackClient> _Ready(
      Meta, VersionInfo, PackData, InstanceDirName, context, SetState) async {
    String VersionID = VersionInfo["targets"][1]["version"];
    String LoaderID = VersionInfo["targets"][0]["name"];
    String LoaderVersionID = VersionInfo["targets"][0]["version"];
    bool isFabric = LoaderID.startsWith(ModLoader().Fabric);
    bool isForge = LoaderID.startsWith(ModLoader().Forge);

    if (isFabric) {
      FabricClient.createClient(
          setState: SetState,
          Meta: Meta,
          VersionID: VersionID,
          LoaderVersion: LoaderVersionID);
    } else if (isForge) {
      Future.delayed(Duration.zero, () {
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => utility.JavaCheck(
                  InstanceConfig: {
                    'java_version': Meta["javaVersion"]["majorVersion"]
                  },
                )).then((value) {
          ForgeClient.createClient(
              setState: SetState,
              Meta: Meta,
              gameVersionID: VersionID,
              forgeVersionID: LoaderVersionID,
              InstanceDirName: InstanceDirName);
        });
      });
    }
    NowEvent = "下載模組包檔案中";
    await DownloadFiles(VersionInfo, InstanceDirName, SetState);
    return this;
  }
}

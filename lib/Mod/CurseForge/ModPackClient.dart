import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'Handler.dart';

class CurseModPackClient implements MinecraftClient {
  Map Meta;

  MinecraftClientHandler handler;

  var setState;

  CurseModPackClient._init(
      {required this.Meta,
      required Map PackMeta,
      required this.handler,
      required String VersionID,
      required SetState,
      required String LoaderVersion,
      required String InstanceDirName,
      required Archive PackArchive}) {}

  static Future<CurseModPackClient> createClient(
      {required Map Meta,
      required Map PackMeta,
      required String VersionID,
      required String InstanceDirName,
      required setState,
      required String LoaderVersion,
      required Archive PackArchive}) async {
    return await new CurseModPackClient._init(
            handler: await new MinecraftClientHandler(),
            SetState: setState,
            Meta: Meta,
            VersionID: VersionID,
            LoaderVersion: LoaderVersion,
            InstanceDirName: InstanceDirName,
            PackMeta: PackMeta,
            PackArchive: PackArchive)
        ._Ready(Meta, PackMeta, VersionID, InstanceDirName, PackArchive,
            LoaderVersion, setState);
  }

  Future<void> DownloadMods(Map PackMeta, InstanceDirName, SetState_) async {
    handler.TotalTaskLength += PackMeta["files"].length;
    PackMeta["files"].forEach((file) async {
      if (!file["required"]) return; //如果非必要檔案則不下載

      Map FileInfo = await CurseForgeHandler.getFileInfo(
          file["projectID"], file["fileID"]);

      late Directory Filepath;
      final String FileName = FileInfo["fileName"];
      if (path.extension(FileName) == ".jar") {
        //類別為模組
        Filepath = InstanceRepository.getModRootDir(InstanceDirName);
      } else if (path.extension(FileName) == ".zip") {
        //類別為資源包
        Filepath =
            InstanceRepository.getResourcePackRootDir(InstanceDirName);
      }

      handler.DownloadFile(FileInfo["downloadUrl"], FileInfo["fileName"],
              Filepath.absolute.path, null, SetState_)
          .timeout(new Duration(milliseconds: 300), onTimeout: () {});
      ;
    });
  }

  Future<void> Overrides(
      Map PackMeta, InstanceDirName, PackArchive, SetState_) async {
    final String OverridesDir = PackMeta["overrides"];
    final String InstanceDir =
        InstanceRepository.getInstanceDir(InstanceDirName).absolute.path;

    for (ArchiveFile file in PackArchive) {
      if (file.toString().startsWith(OverridesDir)) {
        handler.TotalTaskLength++;
        final data = file.content as List<int>;
        if (file.isFile) {
          File(InstanceDir +
              utility.split(file.name, OverridesDir, max: 1).join(""))
            ..createSync(recursive: true)
            ..writeAsBytes(data).then((value) => SetState_(() {
                  handler.DoneTaskLength++;
                }));
        } else {
          Directory(InstanceDir +
                  utility.split(file.name, OverridesDir, max: 1).join(""))
              .create(recursive: true)
              .then((value) => SetState_(() {
                    handler.DoneTaskLength++;
                  }));
        }
      }
    }
  }

  Future<CurseModPackClient> _Ready(Meta, PackMeta, VersionID, InstanceDirName,
      PackArchive, LoaderVersion, SetState) async {
    String LoaderID = PackMeta["minecraft"]["modLoaders"][0]["id"];
    bool isFabric = LoaderID.startsWith(ModLoader().Fabric);
    bool isForge = LoaderID.startsWith(ModLoader().Forge);

    if (isFabric) {
      FabricClient.createClient(
          setState: SetState,
          Meta: Meta,
          VersionID: VersionID,
          LoaderVersion: LoaderVersion);
    } else if (isForge) {
      ForgeClient.createClient(
          setState: SetState,
          Meta: Meta,
          gameVersionID: VersionID,
          forgeVersionID: LoaderVersion,
          InstanceDirName: InstanceDirName);
    }
    await DownloadMods(PackMeta, InstanceDirName, SetState);
    await Overrides(PackMeta, InstanceDirName, PackArchive, SetState)
        .then((value) => PackArchive = Null);
    return this;
  }
}

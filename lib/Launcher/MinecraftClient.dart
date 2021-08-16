import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../path.dart';
import 'Arguments.dart';
import 'CheckData.dart';

double Progress = 0.0;
List<String> RuningTasks = [];

abstract class MinecraftClient {
  Map get Meta;

  MinecraftClientHandler get handler;

  get setState;
}

class MinecraftClientHandler {
  num DoneTaskLength = 0;
  num TotalTaskLength = 1;

  void ChangeProgress(setState_) {
    Progress = DoneTaskLength / TotalTaskLength;
    setState_(() {});
  }

  Future<void> DownloadFile(
      String url, String filename, String path, fileSha1, SetState_) async {
    var dir_ = path;
    File file = await File(join(dir_, filename))
      ..createSync(recursive: true);
    if (CheckData().CheckSha1Sync(file, fileSha1)) {
      DoneTaskLength++;
      RuningTasks.remove(filename);
      return;
    }
    ChangeProgress(SetState_);
    try {
      await http.get(Uri.parse(url)).then((response) async {
        await file.writeAsBytes(response.bodyBytes);
      });
    } catch (err) {
      print(err);
    }
    DoneTaskLength++; //Done Download
    RuningTasks.remove(filename);
    ChangeProgress(SetState_);
  }

  Future GetClientJar(body, VersionID, SetState_) async {
    RuningTasks.add("client.jar");
    DownloadFile(
        body["downloads"]["client"]["url"],
        "client.jar",
        join(dataHome.absolute.path, "versions", VersionID),
        body["downloads"]["client"]["sha1"],
        SetState_);
  }

  Future GetArgs(body, VersionID) async {
    RuningTasks.add("處理遊戲參數中");
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    ArgsFile.createSync(recursive: true);
    ArgsFile.writeAsStringSync(
        json.encode(Arguments().GetArgsString(VersionID, body)));
    RuningTasks.remove("處理遊戲參數中");
  }

  Future DownloadAssets(data, version, SetState_) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    TotalTaskLength = TotalTaskLength + body["objects"].keys.length;
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${version}.json"))
      ..createSync(recursive: true);
    IndexFile.writeAsStringSync(response.body);
    for (var i in body["objects"].keys) {
      String hash = body["objects"][i]["hash"].toString();
      RuningTasks.add(hash);
      await DownloadFile(
              "https://resources.download.minecraft.net/${hash.substring(0, 2)}/${hash}",
              hash,
              join(dataHome.absolute.path, "assets", "objects",
                  hash.substring(0, 2)),
              hash,
              SetState_)
          .timeout(new Duration(milliseconds: 120), onTimeout: () {});
    }
  }

  Future DownloadLib(body, version, SetState_) async {
    Libraries.fromList(body['libraries']).libraries.forEach((lib) {
      if (lib.isnatives) {
        if (lib.downloads.classifiers != null) {
          TotalTaskLength++;
          DownloadNatives(lib.downloads.classifiers!, version, SetState_);
        }
        Artifact artifact = lib.downloads.artifact;
        TotalTaskLength++;
        List split_ = artifact.path.split("/");
        RuningTasks.add(split_[split_.length - 1]);
        DownloadFile(
            artifact.url,
            split_[split_.length - 1],
            join(
                dataHome.absolute.path,
                "versions",
                version,
                "libraries",
                ModLoader().None,
                split_.sublist(0, split_.length - 2).join("/")),
            artifact.sha1,
            SetState_);
      }
    });
  }

  Future DownloadNatives(Classifiers classifiers, version, SetState_) async {
    List split_ = classifiers.path.split("/");
    DownloadFile(
            classifiers.url,
            split_[split_.length - 1],
            join(dataHome.absolute.path, "versions", version, "natives"),
            classifiers.sha1,
            SetState_)
        .then((value) => UnZip(split_[split_.length - 1],
            join(dataHome.absolute.path, "versions", version, "natives")));
  }

  Future UnZip(fileName, dir_) async {
    var file = new File(join(dir_, fileName));
    final bytes = await file.readAsBytesSync();
    final archive = await ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final ZipFileName = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        if (ZipFileName.endsWith(".git") ||
            ZipFileName.endsWith(".sha1") ||
            ZipFileName.contains("META-INF")) break;
        await File(join(dir_, ZipFileName))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        await Directory(join(dir_, ZipFileName))
          ..create(recursive: true);
      }
    }
    file.delete(recursive: true);
  }

  Future<MinecraftClientHandler> Install(Meta, VersionID, SetState) async {
    await this.DownloadLib(Meta, VersionID, SetState);
    await this.GetClientJar(Meta, VersionID, SetState);
    await this.GetArgs(Meta, VersionID);
    await this.DownloadAssets(Meta, VersionID, SetState);
    return this;
  }
}

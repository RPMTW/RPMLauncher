import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../path.dart';
import 'Arguments.dart';
import 'CheckData.dart';

num RemainingTime = 0;
double DownloadProgress = 0.0;

abstract class MinecraftClient {
  Directory get InstanceDir;

  Map get Meta;

  MinecraftClientHandler get handler;

  get SetState;
}

class MinecraftClientHandler {
  num DownloadDoneFileLength = 0;
  num DownloadTotalFileLength = 1;
  var _startTime = 0;

  void ChangeProgress(setState_) {
    setState_(() {
      int elapsedTime = DateTime.now().millisecondsSinceEpoch - _startTime;
      num allTimeForDownloading =
          elapsedTime * DownloadTotalFileLength / DownloadDoneFileLength;
      if (allTimeForDownloading.isNaN || allTimeForDownloading.isInfinite)
        allTimeForDownloading = 0;
      int time = allTimeForDownloading.toInt() - elapsedTime;
      DownloadProgress = DownloadDoneFileLength / DownloadTotalFileLength;
      RemainingTime = time;
    });
  }

  Future<void> DownloadFile(
      String url, String filename, String path, fileSha1, SetState_) async {
    var dir_ = path;
    File file = await File(join(dir_, filename))
      ..createSync(recursive: true);
    if (CheckData().Assets(file, fileSha1)) {
      DownloadDoneFileLength++;
      return;
    }
    ChangeProgress(SetState_);
    await http.get(Uri.parse(url)).then((response) async {
      await file.writeAsBytes(response.bodyBytes);
    });
    DownloadDoneFileLength++; //Done Download
    ChangeProgress(SetState_);
  }

  Future GetClientJar(body, VersionID, SetState_) async {
    DownloadFile(
        body["downloads"]["client"]["url"],
        "client.jar",
        join(dataHome.absolute.path, "versions", VersionID),
        body["downloads"]["client"]["sha1"],
        SetState_);
  }

  Future GetArgs(body, InstanceDir, VersionID) async {
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    ArgsFile.createSync(recursive: true);
    ArgsFile.writeAsStringSync(
        json.encode(Arguments().GetArgsString(VersionID, body)));
  }

  Future DownloadAssets(data, version, SetState_) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    DownloadTotalFileLength =
        DownloadTotalFileLength + body["objects"].keys.length;
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${version}.json"))
      ..createSync(recursive: true);
    IndexFile.writeAsStringSync(response.body);
    for (var i in body["objects"].keys) {
      var hash = body["objects"][i]["hash"].toString();
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
    body["libraries"]
      ..forEach((lib) {
        if ((lib["natives"] != null &&
                !lib["natives"].keys.contains(utility.getOS())) ||
            utility.ParseLibRule(lib)) return;
        if (lib["downloads"].keys.contains("classifiers")) {
          var classifiers = lib["downloads"]["classifiers"];
          DownloadTotalFileLength++;
          DownloadNatives(classifiers, version, SetState_);
        }
        if (lib["downloads"].keys.contains("artifact")) {
          var artifact = lib["downloads"]["artifact"];
          DownloadTotalFileLength++;
          List split_ = artifact["path"].toString().split("/");
          DownloadFile(
              artifact["url"],
              split_[split_.length - 1],
              join(
                  dataHome.absolute.path,
                  "versions",
                  version,
                  "libraries",
                  ModLoader().None,
                  split_.sublist(0, split_.length - 2).join("/")),
              artifact["sha1"],
              SetState_);
        }
      });
  }

  Future DownloadNatives(i, version, SetState_) async {
    var SystemNatives = "natives-${Platform.operatingSystem}";
    if (i.keys.contains(SystemNatives)) {
      List split_ = i[SystemNatives]["path"].split("/");
      DownloadFile(
              i[SystemNatives]["url"],
              split_[split_.length - 1],
              join(dataHome.absolute.path, "versions", version, "natives"),
              i[SystemNatives]["sha1"],
              SetState_)
          .then((value) => UnZip(split_[split_.length - 1],
              join(dataHome.absolute.path, "versions", version, "natives")));
    }
  }

  Future UnZip(fileName, dir_) async {
    var file = new File(join(dir_, fileName));
    final bytes = await file.readAsBytesSync();
    final archive = await ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final ZipFileName = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        if (ZipFileName.endsWith(".git") || ZipFileName.endsWith(".sha1"))
          break;
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

  Future<MinecraftClientHandler> Install(
      Meta, VersionID, InstanceDir, SetState) async {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    this.DownloadLib(Meta, VersionID, SetState);
    this.GetClientJar(Meta, VersionID, SetState);
    this.GetArgs(Meta, InstanceDir, VersionID);
    this.DownloadAssets(Meta, VersionID, SetState);
    return this;
  }
}

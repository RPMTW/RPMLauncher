import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../path.dart';
import 'CheckData.dart';

abstract class MinecraftClient {

  MinecraftClientProcesses get handler;
  String get VersionDataUrl;
  String get VersionID;
  get setState_;

}
class MinecraftClientProcesses {
  late double _DownloadProgress;
  num _DownloadDoneFileLength = 0;
  num _DownloadTotalFileLength = 1;
  var _startTime = 0;
  num _RemainingTime = 0;


  void ChangeProgress(setState_) {
    setState_(() {
      _DownloadProgress = _DownloadDoneFileLength / _DownloadTotalFileLength;
      int elapsedTime = DateTime.now().millisecondsSinceEpoch - _startTime;
      num allTimeForDownloading =
          elapsedTime * _DownloadTotalFileLength / _DownloadDoneFileLength;
      if (allTimeForDownloading.isNaN || allTimeForDownloading.isInfinite)
        allTimeForDownloading = 0;
      int time = allTimeForDownloading.toInt() - elapsedTime;
      _RemainingTime = time;
    });
  }
  Future<void> DownloadFile(
      String url, String filename, String path, setState_, fileSha1) async {
    var dir_ = path;
    File file = await File(join(dir_, filename))
      ..createSync(recursive: true);
    if (CheckData().Assets(file, fileSha1)) {
      _DownloadDoneFileLength = _DownloadDoneFileLength + 1;
      return;
    }
    ChangeProgress(setState_);
    await http.get(Uri.parse(url)).then((response) async {
      await file.writeAsBytes(response.bodyBytes);
    });
    if (filename.contains("natives-${Platform.operatingSystem}")) {
      //如果是natives
      final bytes = await file.readAsBytesSync();
      final archive = await ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final ZipFileName = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
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
    _DownloadDoneFileLength = _DownloadDoneFileLength + 1; //Done Download
    ChangeProgress(setState_);
  }

  Future DownloadNatives(i, version, setState_) async {
    var SystemNatives = "natives-${Platform.operatingSystem}";
    if (i.keys.contains(SystemNatives)) {
      List split_ = i[SystemNatives]["path"].split("/");
      DownloadFile(
          i[SystemNatives]["url"],
          split_[split_.length - 1],
          join(dataHome.absolute.path, "versions", version, "natives"),
          setState_,
          i[SystemNatives]["sha1"]);
    }
  }

  Future DownloadGame(setState_, data_url, version) async {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse(data_url);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    DownloadFile(
      //Download Client File
        body["downloads"]["client"]["url"],
        "client.jar",
        join(dataHome.absolute.path, "versions", version),
        setState_,
        body["downloads"]["client"]["sha1"]);
    File(join(dataHome.absolute.path, "versions", version, "args.json"))
        .writeAsStringSync(json.encode(body["arguments"]));
    DownloadLib(body, version, setState_);
    DownloadAssets(body, setState_, version);
  }

  Future DownloadAssets(data, setState_, version) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    _DownloadTotalFileLength =
        _DownloadTotalFileLength + body["objects"].keys.length;
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
          setState_,
          hash)
          .timeout(new Duration(milliseconds: 120), onTimeout: () {});
    }
  }

  Future DownloadLib(body, version, setState_) async {
    body["libraries"]
      ..forEach((lib) {
        if ((lib["natives"] != null &&
            !lib["natives"].keys.contains(utility().getOS())) ||
            utility().ParseLibRule(lib)) return;
        if (lib["downloads"].keys.contains("classifiers")) {
          var classifiers = lib["downloads"]["classifiers"];
          _DownloadTotalFileLength++;
          DownloadNatives(classifiers, version, setState_);
        }
        if (lib["downloads"].keys.contains("artifact")) {
          var artifact = lib["downloads"]["artifact"];
          _DownloadTotalFileLength++;
          List split_ = artifact["path"].toString().split("/");
          DownloadFile(
              artifact["url"],
              split_[split_.length - 1],
              join(dataHome.absolute.path, "versions", version, "libraries",
                  split_.sublist(0, split_.length - 2).join("/")),
              setState_,
              artifact["sha1"]);
        }
      });
  }
}
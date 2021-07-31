import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/Arguments.dart';
import 'package:rpmlauncher/MCLauncher/CheckData.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';
import '../path.dart';

class DownloadGameScreen_ extends State<DownloadGameScreen> {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;
  late var IsFabric;

  num _DownloadDoneFileLength = 0;
  num _DownloadTotalFileLength = 1;
  var _startTime = 0;
  num _RemainingTime = 0;
  late double _DownloadProgress = 0.0;

  DownloadGameScreen_(
      border_colour_, name_controller_, InstanceDir_, Data_, ModLoaderName_) {
    border_colour = border_colour_;
    name_controller = name_controller_;
    InstanceDir = InstanceDir_;
    Data = Data_;
    ModLoaderName = ModLoaderName_;
  }

  @override
  void initState() {
    super.initState();
    IsFabric = ModLoader()
            .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName)) ==
        ModLoader().Fabric;
  }

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
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", version, "args.json"));
    ArgsFile.createSync(recursive: true);
    ArgsFile.writeAsStringSync(
        json.encode(body[Arguments().ParseVersion(body)]));
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

  Widget build(BuildContext context) {
    FutureBuilder(
        future: FabricAPI().IsCompatibleVersion(Data["id"]),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (IsFabric && snapshot.data != null && !snapshot.data) {
            //偵測到不相容於目前版本的Fabric
            return AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text("錯誤資訊"),
              content: Text("目前選擇的Minecraft版本與選擇的模組載入器版本不相容"),
              actions: <Widget>[
                TextButton(
                  child: Text(i18n().Format("OK")),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      title: Text("建立安裝檔"),
      content: Row(
        children: [
          Text("安裝檔名稱: "),
          Expanded(
              child: TextField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: border_colour, width: 5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: border_colour, width: 3.0),
                    ),
                  ),
                  controller: name_controller)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(i18n().Format("gui.cancel")),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(i18n().Format("gui.confirm")),
          onPressed: () async {
            if (name_controller.text != "" &&
                !File(join(InstanceDir.absolute.path, name_controller.text,
                        "instance.cfg"))
                    .existsSync()) {
              border_colour = Colors.lightBlue;
              ;
              var new_ = true;
              File(join(InstanceDir.absolute.path, name_controller.text,
                  "instance.cfg"))
                ..createSync(recursive: true)
                ..writeAsStringSync("name=" +
                    name_controller.text +
                    "\n" +
                    "version=" +
                    Data["id"].toString());
              Navigator.of(context).pop();
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => LauncherHome()),
              );
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(builder: (context, setState) {
                      if (new_ == true) {
                        DownloadGame(
                            setState, Data["url"], Data["id"].toString());
                        new_ = false;
                      }
                      if (_DownloadProgress == 1) {
                        return AlertDialog(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text("下載完成"),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("關閉"))
                          ],
                        );
                      } else {
                        return WillPopScope(
                          onWillPop: () => Future.value(false),
                          child: AlertDialog(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text("下載遊戲資料中...\n尚未下載完成，請勿關閉此視窗"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: _DownloadProgress,
                                ),
                                Text(
                                    "${(_DownloadProgress * 100).toStringAsFixed(2)}%"),
                                Text(
                                    "預計剩餘時間: ${DateTime.fromMillisecondsSinceEpoch(_RemainingTime.toInt()).minute} 分鐘 ${DateTime.fromMillisecondsSinceEpoch(_RemainingTime.toInt()).second} 秒"),
                              ],
                            ),
                            actions: <Widget>[],
                          ),
                        );
                      }
                    });
                  });
            } else {
              border_colour = Colors.red;
            }
          },
        ),
      ],
    );
  }
}

class DownloadGameScreen extends StatefulWidget {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;

  DownloadGameScreen(
      border_colour_, name_controller_, InstanceDir_, Data_, ModLoaderName_) {
    border_colour = border_colour_;
    name_controller = name_controller_;
    InstanceDir = InstanceDir_;
    Data = Data_;
    ModLoaderName = ModLoaderName_;
  }

  @override
  DownloadGameScreen_ createState() => DownloadGameScreen_(
      border_colour, name_controller, InstanceDir, Data, ModLoaderName);
}

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:RPMLauncher/MCLauncher/CheckData.dart';
import 'package:RPMLauncher/Screen/Log.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/i18n.dart';

import '../path.dart';

class CheckAssetsScreen_ extends State<CheckAssetsScreen> {
  late Directory InstanceDir;
  late ReceivePort port;
  late Isolate isolate;
  bool finish = false;
  var CheckAssetsProgress = 0.0;
  bool CheckAssets = Config().GetValue("check_assets");

  CheckAssetsScreen_(InstanceDir_) {
    InstanceDir = Directory(InstanceDir_);
  }

  @override
  void initState() {
    super.initState();

    if (CheckAssets) {
      //是否檢查資源檔案完整性
      Thread();
    } else {
      finish = true;
    }
  }

  Thread() async {
    port = ReceivePort();
    Directory LauncherFolder = dataHome;
    Directory tempDir = Directory(join(LauncherFolder.absolute.path, "temp"));
    tempDir.createSync(recursive: true);
    if (Directory(join(tempDir.absolute.path, "instance")).existsSync())
      Directory(join(tempDir.absolute.path, "instance")).deleteSync();
    Link(join(tempDir.absolute.path, "instance"))
        .createSync(InstanceDir.absolute.path);
    isolate = await Isolate.spawn(InstanceAssets, port.sendPort);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
        finish = true;
        Directory(join(tempDir.absolute.path, "instance")).deleteSync();
        setState(() {});
      }
    });
    port.listen((message) {
        setState(() {
          CheckAssetsProgress =
              double.parse(message.toString());
        });
    });
  }

  static InstanceAssets(SendPort port) async {
    var TotalAssetsFiles;
    var DoneAssetsFiles = 0;
    Directory tempDir = Directory(join(dataHome.absolute.path, "temp"));
    Directory InstanceDir = Directory(join(tempDir.absolute.path, "instance"));
    var Downloads = [];
    var InstanceConfig = json.decode(
        File(join(InstanceDir.absolute.path, "instance.json"))
            .readAsStringSync());
    var VersionID = InstanceConfig["version"];
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${VersionID}.json"));
    Directory AssetsObjectDir =
        Directory(join(dataHome.absolute.path, "assets", "objects"));
    Map<String, dynamic> IndexObject =
        jsonDecode(IndexFile.readAsStringSync(encoding: utf8));

    TotalAssetsFiles = IndexObject["objects"].keys.length;

    for (var i in IndexObject["objects"].keys) {
      var hash = IndexObject["objects"][i]["hash"].toString();
      File AssetsFile =
          File(join(AssetsObjectDir.absolute.path, hash.substring(0, 2), hash));
      if (AssetsFile.existsSync() && CheckData().Assets(AssetsFile, hash)) {
        DoneAssetsFiles++;
        port.send(DoneAssetsFiles / TotalAssetsFiles);
      } else {
        Downloads.add(hash);
        port.send(DoneAssetsFiles / TotalAssetsFiles);
      }
    }
    if (DoneAssetsFiles < TotalAssetsFiles) {
      Downloads.forEach((AssetsHash) async {
        File file = File(join(AssetsObjectDir.absolute.path,
            AssetsHash.substring(0, 2), AssetsHash))
          ..createSync(recursive: true);
        await http
            .get(Uri.parse(
                "https://resources.download.minecraft.net/${AssetsHash.substring(0, 2)}/${AssetsHash}"))
            .then((response) async {
          await file.writeAsBytes(response.bodyBytes);
        });
      });
      port.send(DoneAssetsFiles / TotalAssetsFiles);
    }
  }

  Widget build(BuildContext context) {
    if (finish == true) {
      return LogScreen(InstanceDir.absolute.path);
    } else {
      return Center(
          child: AlertDialog(
        title: Text(i18n.Format("launcher.assets.check"), textAlign: TextAlign.center),
        content: LinearProgressIndicator(
          value: CheckAssetsProgress,
        ),
      ));
    }
  }
}

class CheckAssetsScreen extends StatefulWidget {
  late var InstanceDir;

  CheckAssetsScreen(InstanceDir_) {
    InstanceDir = InstanceDir_;
  }

  @override
  CheckAssetsScreen_ createState() => CheckAssetsScreen_(InstanceDir);
}
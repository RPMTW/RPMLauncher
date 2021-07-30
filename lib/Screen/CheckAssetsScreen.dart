import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/CheckData.dart';
import 'package:rpmlauncher/Screen/Log.dart';

import '../parser.dart';
import '../path.dart';

class CheckAssetsScreen_ extends State<CheckAssetsScreen> {
  late Directory InstanceDir;
  late ReceivePort port;
  late Isolate isolate;
  bool finish=false;
  CheckAssetsScreen_(InstanceDir_) {
    InstanceDir = Directory(InstanceDir_);
  }
  @override
  void initState() {
    super.initState();
    b();
  }
    b()async{
    port = ReceivePort();
    //InstanceAssets(InstanceDir, setState);
    Directory LauncherFolder = dataHome;
    Directory tmpDir =Directory(join(LauncherFolder.absolute.path, "tmp"));
    tmpDir.createSync(recursive: true);
    if (Directory(join(tmpDir.absolute.path,"instance")).existsSync())Directory(join(tmpDir.absolute.path,"instance")).deleteSync();
    Link(join(tmpDir.absolute.path,"instance")).createSync(InstanceDir.absolute.path);
    isolate=await Isolate.spawn(InstanceAssets, port.sendPort);
    var exit=ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) { // A null message means the isolate exited
        print("finish");
        finish=true;
        Directory(join(tmpDir.absolute.path,"instance")).deleteSync();
        setState(() {

        });
      }
    });

  }
  static InstanceAssets(SendPort port) async {
    print("start");
    var TotalAssetsFiles;
    var DoneAssetsFiles = 0;
    Directory LauncherFolder = dataHome;
    Directory tmpDir =Directory(join(LauncherFolder.absolute.path, "tmp"));
    Directory InstanceDir=Directory(join(tmpDir.absolute.path,"instance"));
    var CheckAssetsProgress;
    var Downloads = [];
    var cfg_file = CFG(File(join(InstanceDir.absolute.path, "instance.cfg"))
            .readAsStringSync())
        .GetParsed();
    var VersionID = cfg_file["version"];
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
      } else {
        Downloads.add(hash);
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
    }
    port.send("finish");
    print("func finish");
  }

  Widget build(BuildContext context) {
    if (finish == true) {
      return LogScreen(InstanceDir.absolute.path);
    } else {
      return Center(
          child: AlertDialog(
        title: Text("核對資源檔案中...", textAlign: TextAlign.center),
        actions: [Center(child: CircularProgressIndicator())],
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

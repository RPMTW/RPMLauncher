import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/CheckData.dart';
import 'package:rpmlauncher/Screen/Log.dart';

import '../parser.dart';
import '../path.dart';

class CheckAssetsScreen_ extends State<CheckAssetsScreen> {
  late var InstanceDir;

  var TotalAssetsFiles;
  var DoneAssetsFiles = 0;
  var Downloads = [];
  var CheckAssetsProgress;

  CheckAssetsScreen_(InstanceDir_) {
    InstanceDir = Directory(InstanceDir_);
  }

  @override
  void initState() {
    super.initState();
    InstanceAssets(InstanceDir, setState);
  }

  Future<void> InstanceAssets(InstanceDir, setState_) async {
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
        setState(() {
          DoneAssetsFiles++;
          CheckAssetsProgress = DoneAssetsFiles / TotalAssetsFiles;
        });
      } else {
        Downloads.add(hash);
      }
    }
    if (DoneAssetsFiles < TotalAssetsFiles) {
      Downloads.forEach((AssetsHash) {
        File file = File(join(AssetsObjectDir.absolute.path,
            AssetsHash.substring(0, 2), AssetsHash))
          ..createSync(recursive: true);
        http
            .get(Uri.parse(
                "https://resources.download.minecraft.net/${AssetsHash.substring(0, 2)}/${AssetsHash}"))
            .then((response) async {
          await file.writeAsBytes(response.bodyBytes);
        });
        setState(() {
          DoneAssetsFiles++;
          CheckAssetsProgress = DoneAssetsFiles / TotalAssetsFiles;
        });
      });
    }
  }

  Widget build(BuildContext context) {
    if (CheckAssetsProgress == 1) {
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

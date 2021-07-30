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
  late var cfg_file;
  late var VersionID;
  late var IndexFile;
  late var AssetsObjectDir;
  late Map<String, dynamic> IndexObject;
  @override
  void initState() {
    super.initState();
    InstanceAssets(InstanceDir, setState);
     cfg_file = CFG(File(join(InstanceDir.absolute.path, "instance.cfg"))
        .readAsStringSync())
        .GetParsed();
     VersionID = cfg_file["version"];
     IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${VersionID}.json"));
     AssetsObjectDir =Directory(join(dataHome.absolute.path, "assets", "objects"));
    IndexObject =jsonDecode(IndexFile.readAsStringSync(encoding: utf8));

  }

  Future<void> InstanceAssets(InstanceDir, setState_) async {

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

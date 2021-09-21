import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Screen/Log.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';
import '../path.dart';

class CheckAssetsScreen_ extends State<CheckAssetsScreen> {
  final Directory InstanceDir;
  var CheckAssetsProgress = 0.0;
  bool CheckAssets = Config.getValue("check_assets");

  CheckAssetsScreen_({required this.InstanceDir});

  @override
  void initState() {
    super.initState();

    if (CheckAssets) {
      //是否檢查資源檔案完整性
      Thread();
    } else {
      CheckAssetsProgress = 1.0;
    }
  }

  Thread() async {
    ReceivePort port = ReceivePort();
    compute(InstanceAssets, [port.sendPort, InstanceDir, dataHome])
        .then((value) => setState(() {
              CheckAssetsProgress = 1.0;
            }));
    port.listen((message) {
      setState(() {
        CheckAssetsProgress = double.parse(message.toString());
      });
    });
  }

  static InstanceAssets(List args) async {
    SendPort port = args[0];
    Directory InstanceDir = args[1];
    Directory dataHome = args[2];

    var TotalAssetsFiles;
    var DoneAssetsFiles = 0;
    var Downloads = [];
    var InstanceConfig = json.decode(
        File(join(InstanceDir.absolute.path, "instance.json"))
            .readAsStringSync());
    var VersionID = InstanceConfig["version"];
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${VersionID}.json"));
    Directory AssetsObjectDir =
        Directory(join(dataHome.absolute.path, "assets", "objects"));
    Map<String, dynamic> IndexObject = jsonDecode(IndexFile.readAsStringSync());

    TotalAssetsFiles = IndexObject["objects"].keys.length;

    for (var i in IndexObject["objects"].keys) {
      var hash = IndexObject["objects"][i]["hash"].toString();
      File AssetsFile =
          File(join(AssetsObjectDir.absolute.path, hash.substring(0, 2), hash));
      if (AssetsFile.existsSync() &&
          CheckData().CheckSha1Sync(AssetsFile, hash)) {
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
    if (CheckAssetsProgress == 1.0) {
      return LogScreen(InstanceRepository.getInstanceDirNameByDir(InstanceDir));
    } else {
      return Center(
          child: AlertDialog(
        title: Text(i18n.format("launcher.assets.check"),
            textAlign: TextAlign.center),
        content: LinearProgressIndicator(
          value: CheckAssetsProgress,
        ),
      ));
    }
  }
}

class CheckAssetsScreen extends StatefulWidget {
  final Directory InstanceDir;

  CheckAssetsScreen({required this.InstanceDir});

  @override
  CheckAssetsScreen_ createState() =>
      CheckAssetsScreen_(InstanceDir: InstanceDir);
}

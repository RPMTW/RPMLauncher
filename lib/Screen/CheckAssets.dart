import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';

class _CheckAssetsScreenState extends State<CheckAssetsScreen> {
  double checkAssetsProgress = 0.0;
  bool checkAssets = Config.getValue("check_assets");

  @override
  void initState() {
    super.initState();

    if (checkAssets) {
      //是否檢查資源檔案完整性
      thread();
    } else {
      checkAssetsProgress = 1.0;
    }

    super.initState();
  }

  thread() async {
    ReceivePort port = ReceivePort();
    compute(instanceAssets, [
      port.sendPort,
      InstanceRepository.instanceConfig(basename(widget.instanceDir.path)),
      dataHome
    ]).then((value) => setState(() {
          checkAssetsProgress = 1.0;
        }));
    port.listen((message) {
      setState(() {
        checkAssetsProgress = double.parse(message.toString());
      });
    });
  }

  static instanceAssets(List args) async {
    SendPort port = args[0];
    InstanceConfig instanceConfig = args[1];
    Directory dataHome = args[2];

    int totalAssetsFiles;
    int doneAssetsFiles = 0;
    List<String> downloads = [];
    String versionID = instanceConfig.version;
    File indexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "$versionID.json"));
    Directory assetsObjectDir =
        Directory(join(dataHome.absolute.path, "assets", "objects"));
    Map<String, dynamic> indexObject = jsonDecode(indexFile.readAsStringSync());

    totalAssetsFiles = indexObject["objects"].keys.length;

    for (var i in indexObject["objects"].keys) {
      var hash = indexObject["objects"][i]["hash"].toString();
      File assetsFile =
          File(join(assetsObjectDir.absolute.path, hash.substring(0, 2), hash));
      if (assetsFile.existsSync() &&
          CheckData.checkSha1Sync(assetsFile, hash)) {
        doneAssetsFiles++;
        port.send(doneAssetsFiles / totalAssetsFiles);
      } else {
        downloads.add(hash);
        port.send(doneAssetsFiles / totalAssetsFiles);
      }
    }
    if (doneAssetsFiles < totalAssetsFiles) {
      downloads.forEach((assetsHash) async {
        File file = File(join(assetsObjectDir.absolute.path,
            assetsHash.substring(0, 2), assetsHash))
          ..createSync(recursive: true);
        await http
            .get(Uri.parse(
                "https://resources.download.minecraft.net/${assetsHash.substring(0, 2)}/$assetsHash"))
            .then((response) async {
          await file.writeAsBytes(response.bodyBytes);
        });
      });
      port.send(doneAssetsFiles / totalAssetsFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (checkAssetsProgress == 1.0) {
        navigator.pop();
        Uttily.openNewWindow(RouteSettings(
          name:
              "/instance/${InstanceRepository.getinstanceDirNameByDir(widget.instanceDir)}/launcher",
        ));
      }
    });

    return Center(
        child: AlertDialog(
      title: Text(I18n.format("launcher.assets.check"),
          textAlign: TextAlign.center),
      content: LinearProgressIndicator(
        value: checkAssetsProgress,
      ),
    ));
  }
}

class CheckAssetsScreen extends StatefulWidget {
  final Directory instanceDir;

  const CheckAssetsScreen({required this.instanceDir});

  @override
  _CheckAssetsScreenState createState() => _CheckAssetsScreenState();
}

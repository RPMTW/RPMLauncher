import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Utility/Data.dart';

class _CheckAssetsScreenState extends State<CheckAssetsScreen> {
  double checkAssetsProgress = 0.0;
  bool checkAssets = Config.getValue("check_assets");
  late InstanceConfig instanceConfig;
  @override
  void initState() {
    super.initState();

    instanceConfig =
        InstanceRepository.instanceConfig(basename(widget.instanceDir.path))!;

    if (checkAssets && instanceConfig.sideEnum.isClient) {
      //是否檢查資源檔案完整性
      thread();
    } else {
      checkAssetsProgress = 1.0;
    }
  }

  thread() async {
    ReceivePort port = ReceivePort();
    compute(instanceAssets, [port.sendPort, instanceConfig, dataHome])
        .then((value) {
      if (mounted) {
        setState(() {
          checkAssetsProgress = 1.0;
        });
      }
    });
    port.listen((message) {
      if (mounted) {
        setState(() {
          checkAssetsProgress = double.parse(message.toString());
        });
      }
    });
  }

  static instanceAssets(List args) async {
    SendPort port = args[0];
    InstanceConfig instanceConfig = args[1];
    Directory dataHome = args[2];

    int totalAssetsFiles;
    int doneAssetsFiles = 0;
    List<String> downloads = [];
    String assetsID = instanceConfig.assetsID;
    File indexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "$assetsID.json"));

    if (!indexFile.existsSync()) {
      //如果沒有資源索引檔案則下載
      MinecraftMeta meta =
          await Uttily.getVanillaVersionMeta(instanceConfig.version);
      String assetsIndexUrl = meta['assetIndex']['url'];

      Response response = await RPMHttpClient().get(assetsIndexUrl,
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        indexFile.createSync(recursive: true);
        indexFile.writeAsStringSync(json.encode(response.data));
      }
    }

    Directory assetsObjectDir =
        Directory(join(dataHome.absolute.path, "assets", "objects"));
    Map<String, dynamic> indexJson = json.decode(indexFile.readAsStringSync());
    Map<String, Map> objects = indexJson["objects"].cast<String, Map>();

    totalAssetsFiles = objects.keys.length;

    for (var i in objects.keys) {
      String hash = objects[i]!["hash"].toString();
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
        Navigator.pop(context);
        Uttily.openNewWindow(
          "/instance/${InstanceRepository.getUUIDByDir(widget.instanceDir)}/launcher",
        );
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

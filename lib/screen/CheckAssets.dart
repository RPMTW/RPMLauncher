import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/launcher/CheckData.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/util/data.dart';

class _CheckAssetsScreenState extends State<CheckAssetsScreen> {
  double checkAssetsProgress = 0.0;
  bool checkAssets = Config.getValue("check_assets");

  @override
  void initState() {
    super.initState();

    InstanceConfig instanceConfig =
        InstanceRepository.instanceConfig(basename(widget.instanceDir.path))!;

    if (checkAssets && instanceConfig.sideEnum.isClient) {
      //是否檢查資源檔案完整性
      thread(instanceConfig);
    } else {
      checkAssetsProgress = 1.0;
    }
  }

  thread(InstanceConfig config) async {
    ReceivePort port = ReceivePort();
    compute(instanceAssets,
        IsolateOption.create(config, ports: [port])).then((value) {
      if (mounted) {
        setState(() {
          checkAssetsProgress = 1.0;
        });
      }
    });

    port.listen((message) {
      if (mounted) {
        checkAssetsProgress = double.parse(message.toString());
        if (checkAssetsProgress == 1.0) {
          Navigator.pop(this.context);
          WindowHandler.create(
            "/instance/${InstanceRepository.getUUIDByDir(widget.instanceDir)}/launcher",
          );
        } else {
          setState(() {});
        }
      }
    });
  }

  static instanceAssets(IsolateOption<InstanceConfig> option) async {
    option.init();
    InstanceConfig config = option.argument;

    int totalAssetsFiles;
    int doneAssetsFiles = 0;
    List<String> downloads = [];
    String assetsID = config.assetsID;
    File indexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "$assetsID.json"));

    if (!indexFile.existsSync()) {
      //如果沒有資源索引檔案則下載
      MinecraftMeta meta = await Util.getVanillaVersionMeta(config.version);
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
        option.sendData(doneAssetsFiles / totalAssetsFiles);
      } else {
        downloads.add(hash);
        option.sendData(doneAssetsFiles / totalAssetsFiles);
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
      option.sendData(doneAssetsFiles / totalAssetsFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
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
  State<CheckAssetsScreen> createState() => _CheckAssetsScreenState();
}

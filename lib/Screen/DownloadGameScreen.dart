import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/MCLauncher/MinecraftClient.dart';
import 'package:rpmlauncher/MCLauncher/VanillaClient.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

class DownloadGameScreen_ extends State<DownloadGameScreen> {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;
  late var IsFabric;

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

  FabricIncompatibleErr(value,context){
    if(value) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          title: Text("錯誤資訊"),
          content: Text("目前選擇的Minecraft版本與選擇的模組載入器版本不相容"),
          actions: <Widget>[
            TextButton(
              child: Text("ok"),
              onPressed: () {
                Navigator.push(context, new MaterialPageRoute(builder: (context) => VersionSelection()));
              },
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    if(IsFabric){
      FabricAPI().IsCompatibleVersion(Data["id"]).then((value) => FabricIncompatibleErr(value,context));
    }
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
            border_colour = Colors.lightBlue;
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
                        // DownloadGame(
                        //     setState, Data["url"], Data["id"].toString());
                        VanillaClient.createClient(
                            setState: setState,
                            InstanceDir: InstanceDir,
                            VersionMetaUrl: Data["url"],
                            VersionID: Data["id"].toString());
                        new_ = false;
                      }
                      if (DownloadProgress == 1) {
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
                                  value: DownloadProgress,
                                ),
                                Text("${(DownloadProgress * 100).toStringAsFixed(2)}%"),
                                Text(
                                    "預計剩餘時間: ${DateTime.fromMillisecondsSinceEpoch(RemainingTime.toInt()).minute} 分鐘 ${DateTime.fromMillisecondsSinceEpoch(RemainingTime.toInt()).second} 秒"),
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

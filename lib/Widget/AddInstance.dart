import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/MCLauncher/MinecraftClient.dart';
import 'package:rpmlauncher/MCLauncher/VanillaClient.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

class AddInstanceWidget extends StatefulWidget {
  var border_colour;
  var InstanceDir;
  var name_controller;
  var Data;
  var ModLoaderID;

  AddInstanceWidget(
      border_colour_, InstanceDir_, name_controller_, Data_, ModLoaderID_) {
    border_colour = border_colour_;
    InstanceDir = InstanceDir_;
    name_controller = name_controller_;
    Data = Data_;
    ModLoaderID = ModLoaderID_;
  }

  @override
  _AddInstanceWidgetState createState() => _AddInstanceWidgetState(
      border_colour, InstanceDir, name_controller, Data, ModLoaderID);
}

class _AddInstanceWidgetState extends State<AddInstanceWidget> {
  var border_colour;
  var InstanceDir;
  var name_controller;
  var Data;
  var ModLoaderID;

  _AddInstanceWidgetState(
      border_colour_, InstanceDir_, name_controller_, Data_, ModLoaderID_) {
    border_colour = border_colour_;
    InstanceDir = InstanceDir_;
    name_controller = name_controller_;
    Data = Data_;
    ModLoaderID = ModLoaderID_;
  }

  @override
  Widget build(BuildContext context) {
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
            controller: name_controller,
            onChanged: (value) {
              setState(() {});
                if (File(join(InstanceDir.absolute.path, value,
                        "instance.json"))
                    .existsSync()) {
                  border_colour = Colors.red;
                } else {
                  border_colour = Colors.lightBlue;
                }
            },
          )),
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
                        "instance.json"))
                    .existsSync()) {
              border_colour = Colors.lightBlue;
              var new_ = true;
              var NewInstanceConfig = {
                "name": name_controller.text,
                "version": Data["id"].toString(),
                "loader": ModLoaderID
              };
              File(join(InstanceDir.absolute.path, name_controller.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));
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
                        if (ModLoaderID == ModLoader().None) {
                          VanillaClient.createClient(
                              setState: setState,
                              InstanceDir: InstanceDir,
                              VersionMetaUrl: Data["url"],
                              VersionID: Data["id"].toString());
                        } else if (ModLoaderID == ModLoader().Fabric) {
                          FabricClient.createClient(
                              setState: setState,
                              InstanceDir: InstanceDir,
                              VersionMetaUrl: Data["url"],
                              VersionID: Data["id"].toString());
                        }
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
                                Text(
                                    "${(DownloadProgress * 100).toStringAsFixed(2)}%"),
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

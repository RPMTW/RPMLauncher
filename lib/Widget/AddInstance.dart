import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/MCLauncher/Fabric/FabricClient.dart';
import 'package:RPMLauncher/MCLauncher/Forge/ForgeClient.dart';
import 'package:RPMLauncher/MCLauncher/GameRepository.dart';
import 'package:RPMLauncher/MCLauncher/MinecraftClient.dart';
import 'package:RPMLauncher/MCLauncher/VanillaClient.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

import '../main.dart';

AddInstanceDialog(Color BorderColour, TextEditingController NameController,
    Map Data, String ModLoaderID, String LoaderVersion, bool isModPack) {
  Directory InstanceDir = GameRepository.getInstanceRootDir();
  if (File(
          join(InstanceDir.absolute.path, NameController.text, "instance.json"))
      .existsSync()) {
    BorderColour = Colors.red;
  } else {
    BorderColour = Colors.lightBlue;
  }
  return StatefulBuilder(builder: (context, setState) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      title: Text(i18n.Format("version.list.instance.add")),
      content: Row(
        children: [
          Text(i18n.Format("edit.instance.homepage.instance.name")),
          Expanded(
              child: TextField(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: BorderColour, width: 5.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: BorderColour, width: 3.0),
              ),
            ),
            controller: NameController,
            onChanged: (value) {
              if (File(join(InstanceDir.absolute.path, value, "instance.json"))
                  .existsSync()) {
                BorderColour = Colors.red;
              } else {
                BorderColour = Colors.lightBlue;
              }
              setState(() {});
            },
          )),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text(i18n.Format("gui.cancel")),
          onPressed: () {
            BorderColour = Colors.lightBlue;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(i18n.Format("gui.confirm")),
          onPressed: () async {
            if (NameController.text != "" &&
                !File(join(InstanceDir.absolute.path, NameController.text,
                        "instance.json"))
                    .existsSync()) {
              BorderColour = Colors.lightBlue;
              final url = Uri.parse(Data["url"]);
              Response response = await get(url);
              Map<String, dynamic> Meta = jsonDecode(response.body);
              var new_ = true;
              var NewInstanceConfig = {
                "name": NameController.text,
                "version": Data["id"].toString(),
                "loader": ModLoaderID,
                "java_version": Meta["javaVersion"]["majorVersion"],
                "loader_version": LoaderVersion
              };
              File(join(InstanceDir.absolute.path, NameController.text,
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
                              Meta: Meta,
                              VersionID: Data["id"].toString());
                        } else if (ModLoaderID == ModLoader().Fabric) {
                          FabricClient.createClient(
                              setState: setState,
                              Meta: Meta,
                              VersionID: Data["id"].toString(),
                              LoaderVersion: LoaderVersion);
                        } else if (ModLoaderID == ModLoader().Forge) {
                          ForgeClient.createClient(
                              setState: setState,
                              Meta: Meta,
                              VersionID: Data["id"].toString());
                        }
                        new_ = false;
                      }
                      if (DownloadProgress == 1) {
                        return AlertDialog(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(i18n.Format("gui.download.done")),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(i18n.Format("gui.close")))
                          ],
                        );
                      } else {
                        return WillPopScope(
                          onWillPop: () => Future.value(false),
                          child: AlertDialog(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(i18n.Format("version.list.downloading"),
                                textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: DownloadProgress,
                                ),
                                Text(
                                    "${(DownloadProgress * 100).toStringAsFixed(2)}%"),
                                Text(
                                    "${i18n.Format("version.list.downloading.time")}: ${DateTime.fromMillisecondsSinceEpoch(RemainingTime.toInt()).minute} ${i18n.Format("gui.time.minutes")} ${DateTime.fromMillisecondsSinceEpoch(RemainingTime.toInt()).second} ${i18n.Format("gui.time.seconds")}"),
                              ],
                            ),
                            actions: <Widget>[],
                          ),
                        );
                      }
                    });
                  });
            } else {
              BorderColour = Colors.red;
            }
          },
        ),
      ],
    );
  });
}

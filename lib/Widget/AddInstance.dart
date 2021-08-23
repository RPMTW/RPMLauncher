import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

import '../main.dart';

AddInstanceDialog(Color BorderColour, TextEditingController NameController,
    Map Data, String ModLoaderID, String LoaderVersion) {
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
              if (value == "" ||
                  File(join(InstanceDir.absolute.path, value, "instance.json"))
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
            bool new_ = false;
            Navigator.of(context).pop();
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => LauncherHome()),
            );
            Future<Map<String, dynamic>> LoadingMeta() async {
              final url = Uri.parse(Data["url"]);
              Response response = await get(url);
              Map<String, dynamic> Meta = jsonDecode(response.body);
              var NewInstanceConfig = {
                "name": NameController.text,
                "version": Data["id"].toString(),
                "loader": ModLoaderID,
                "java_version": Meta["javaVersion"]["majorVersion"],
                "loader_version": LoaderVersion,
                "play_time": 0
              };
              File(join(InstanceDir.absolute.path, NameController.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));
              return Meta;
            }

            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FutureBuilder(
                      future: LoadingMeta(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          new_ = true;
                          return StatefulBuilder(builder: (context, setState) {
                            if (new_ == true) {
                              Map<String, dynamic> Meta = snapshot.data;
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
                                    gameVersionID: Data["id"].toString(),
                                    forgeVersionID: LoaderVersion,
                                    InstanceDirName: NameController.text);
                              }
                              new_ = false;
                            }
                            if (Progress == 1 && finish) {
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
                                  title: Text(NowEvent,
                                      textAlign: TextAlign.center),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Progress == 0.0
                                          ? LinearProgressIndicator()
                                          : LinearProgressIndicator(
                                              value: Progress,
                                            ),
                                      Text(
                                          "${(Progress * 100).toStringAsFixed(2)}%")
                                    ],
                                  ),
                                  actions: <Widget>[],
                                ),
                              );
                            }
                          });
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      });
                });
          },
        ),
      ],
    );
  });
}

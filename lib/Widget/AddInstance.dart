import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';
import 'RWLLoading.dart';

AddInstanceDialog(Color BorderColour, TextEditingController NameController,
    Map Data, ModLoaders ModLoaderID, String LoaderVersion) {
  Directory InstanceDir = GameRepository.getInstanceRootDir();
  if (!utility.ValidInstanceName(NameController.text)) {
    BorderColour = Colors.red;
  } else {
    BorderColour = Colors.lightBlue;
  }
  return StatefulBuilder(builder: (context, setState) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      title: Text(i18n.format("version.list.instance.add")),
      content: Row(
        children: [
          Text(i18n.format("edit.instance.homepage.instance.name")),
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
              if (!utility.ValidInstanceName(value)) {
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
          child: Text(i18n.format("gui.cancel")),
          onPressed: () {
            BorderColour = Colors.lightBlue;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(i18n.format("gui.confirm")),
          onPressed: () async {
            bool new_ = false;
            navigator.pop();
            navigator.push(
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            Future<Map<String, dynamic>> LoadingMeta() async {
              final url = Uri.parse(Data["url"]);
              Response response = await get(url);
              Map<String, dynamic> Meta = jsonDecode(response.body);
              var NewInstanceConfig = {
                "name": NameController.text,
                "version": Data["id"].toString(),
                "loader": ModLoaderID.fixedString,
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
                              if (ModLoaderID == ModLoaders.Vanilla) {
                                VanillaClient.createClient(
                                    SetState: setState,
                                    Meta: Meta,
                                    VersionID: Data["id"].toString());
                              } else if (ModLoaderID == ModLoaders.Fabric) {
                                FabricClient.createClient(
                                    SetState: setState,
                                    Meta: Meta,
                                    VersionID: Data["id"].toString(),
                                    LoaderVersion: LoaderVersion);
                              } else if (ModLoaderID == ModLoaders.Forge) {
                                ForgeClient.createClient(
                                    setState: setState,
                                    Meta: Meta,
                                    gameVersionID: Data["id"].toString(),
                                    forgeVersionID: LoaderVersion,
                                    InstanceDirName: NameController.text);
                              }
                              new_ = false;
                            }
                            if (infos.progress == 1 && finish) {
                              return AlertDialog(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(i18n.format("gui.download.done")),
                                actions: <Widget>[
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(i18n.format("gui.close")))
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
                                      infos.progress == 0.0
                                          ? LinearProgressIndicator()
                                          : LinearProgressIndicator(
                                              value: infos.progress,
                                            ),
                                      Text(
                                          "${(infos.progress * 100).toStringAsFixed(2)}%")
                                    ],
                                  ),
                                  actions: <Widget>[],
                                ),
                              );
                            }
                          });
                        } else {
                          return Center(child: RWLLoading());
                        }
                      });
                });
          },
        ),
      ],
    );
  });
}

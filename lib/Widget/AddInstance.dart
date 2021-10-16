import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';
import 'RWLLoading.dart';

AddInstanceDialog(Color borderColour, TextEditingController nameController,
    Map data, ModLoaders ModLoaderID, String loaderVersion) {
  if (!utility.ValidInstanceName(nameController.text)) {
    borderColour = Colors.red;
  } else {
    borderColour = Colors.lightBlue;
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
                borderSide: BorderSide(color: borderColour, width: 5.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColour, width: 3.0),
              ),
            ),
            controller: nameController,
            onChanged: (value) {
              if (!utility.ValidInstanceName(value)) {
                borderColour = Colors.red;
              } else {
                borderColour = Colors.lightBlue;
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
            borderColour = Colors.lightBlue;
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
              final url = Uri.parse(data["url"]);
              Response response = await get(url);
              Map<String, dynamic> meta = jsonDecode(response.body);

              File _file =
                  InstanceRepository.instanceConfigFile(nameController.text);

              InstanceConfig config = InstanceConfig(
                file: _file,
                name: nameController.text,
                version: data["id"].toString(),
                loader: ModLoaderID.fixedString,
                javaVersion: meta["javaVersion"]["majorVersion"] ?? 8,
                loaderVersion: loaderVersion,
              );

              _file
                ..createSync(recursive: true)
                ..writeAsStringSync(config.toString());

              return meta;
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
                              Map<String, dynamic> meta = snapshot.data;
                              if (ModLoaderID == ModLoaders.vanilla) {
                                VanillaClient.createClient(
                                        setState: setState,
                                        Meta: meta,
                                        versionID: data["id"].toString(),
                                        instance: Instance(nameController.text))
                                    .then((value) {
                                  finish = true;
                                  setState(() {});
                                });
                              } else if (ModLoaderID == ModLoaders.fabric) {
                                FabricClient.createClient(
                                        setState: setState,
                                        meta: meta,
                                        versionID: data["id"].toString(),
                                        loaderVersion: loaderVersion,
                                        instance: Instance(nameController.text))
                                    .then((value) {
                                  finish = true;
                                  setState(() {});
                                });
                              } else if (ModLoaderID == ModLoaders.forge) {
                                ForgeClient.createClient(
                                        setState: setState,
                                        meta: meta,
                                        gameVersionID: data["id"].toString(),
                                        forgeVersionID: loaderVersion,
                                        instance: Instance(nameController.text))
                                    .then((value) {
                                  finish = true;
                                  setState(() {});
                                });
                              }
                              new_ = false;
                            }
                            if (infos.progress == 1.0 && finish) {
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
                                  title: Text(nowEvent,
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

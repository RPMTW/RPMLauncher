import 'dart:io';

import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

import '../main.dart';
import 'RWLLoading.dart';

class AddInstanceDialog extends StatelessWidget {
  Color borderColour;
  final TextEditingController nameController;
  final MCVersion version;
  final ModLoaders modLoaderID;
  final String loaderVersion;

  AddInstanceDialog(this.borderColour, this.nameController, this.version,
      this.modLoaderID, this.loaderVersion);

  @override
  Widget build(BuildContext context) {
    if (!Uttily.validInstanceName(nameController.text)) {
      borderColour = Colors.red;
    } else {
      borderColour = Colors.lightBlue;
    }
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format("version.list.instance.add")),
        content: Row(
          children: [
            Text(I18n.format("edit.instance.homepage.instance.name")),
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
                if (!Uttily.validInstanceName(value)) {
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
            child: Text(I18n.format("gui.cancel")),
            onPressed: () {
              borderColour = Colors.lightBlue;
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(I18n.format("gui.confirm")),
            onPressed: () async {
              if (!Uttily.validInstanceName(nameController.text)) return;
              bool new_ = false;
              navigator.pop();
              navigator.push(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              Future<MinecraftMeta> loadingMeta() async {
                MinecraftMeta meta = await version.meta;

                File _file =
                    InstanceRepository.instanceConfigFile(nameController.text);

                InstanceConfig config = InstanceConfig(
                  file: _file,
                  name: nameController.text,
                  version: version.id,
                  loader: modLoaderID.fixedString,
                  javaVersion: meta["javaVersion"]["majorVersion"] ?? 8,
                  loaderVersion: loaderVersion,
                );

                config.createConfigFile();

                return meta;
              }

              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FutureBuilder(
                        future: loadingMeta(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            new_ = true;
                            return StatefulBuilder(
                                builder: (context, setState) {
                              if (new_ == true) {
                                MinecraftMeta meta = snapshot.data;
                                if (modLoaderID == ModLoaders.vanilla) {
                                  VanillaClient.createClient(
                                          setState: setState,
                                          meta: meta,
                                          versionID: version.id,
                                          instance:
                                              Instance(nameController.text))
                                      .whenComplete(() {
                                    finish = true;
                                    setState(() {});
                                  });
                                } else if (modLoaderID == ModLoaders.fabric) {
                                  FabricClient.createClient(
                                          setState: setState,
                                          meta: meta,
                                          versionID: version.id,
                                          loaderVersion: loaderVersion,
                                          instance:
                                              Instance(nameController.text))
                                      .whenComplete(() {
                                    finish = true;
                                    setState(() {});
                                  });
                                } else if (modLoaderID == ModLoaders.forge) {
                                  ForgeClient.createClient(
                                          setState: setState,
                                          meta: meta,
                                          gameVersionID: version.id,
                                          forgeVersionID: loaderVersion,
                                          instance:
                                              Instance(nameController.text))
                                      .whenComplete(() {
                                    finish = true;
                                    setState(() {});
                                  });
                                }
                                new_ = false;
                              }
                              if (infos.progress == 1.0 && finish) {
                                return AlertDialog(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(I18n.format("gui.download.done")),
                                  actions: <Widget>[
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(I18n.format("gui.close")))
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
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
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
}

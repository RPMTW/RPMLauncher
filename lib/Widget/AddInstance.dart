import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import 'RWLLoading.dart';

class AddInstanceDialog extends StatefulWidget {
  final String instanceName;
  final MCVersion version;
  final ModLoader modLoaderID;
  final String loaderVersion;

  const AddInstanceDialog(
      this.instanceName, this.version, this.modLoaderID, this.loaderVersion);

  @override
  State<AddInstanceDialog> createState() => _AddInstanceDialogState();
}

class _AddInstanceDialogState extends State<AddInstanceDialog> {
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    _nameController.text = widget.instanceName;
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format("version.list.instance.add")),
        content: Row(
          children: [
            Text(I18n.format("edit.instance.homepage.instance.name")),
            Expanded(
                child: RPMTextField(
              controller: _nameController,
              onChanged: (value) {
                setState(() {});
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            child: Text(I18n.format("gui.cancel")),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(I18n.format("gui.confirm")),
            onPressed: () async {
              finish = false;
              bool new_ = false;
              late String uuid;
              navigator.pop();
              navigator.push(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              Future<MinecraftMeta> loadingMeta() async {
                MinecraftMeta meta = await widget.version.meta;

                InstanceConfig config = InstanceConfig(
                    uuid: Uuid().v4(),
                    name: _nameController.text,
                    version: widget.version.id,
                    loader: widget.modLoaderID.fixedString,
                    javaVersion: meta["javaVersion"]["majorVersion"] ?? 8,
                    loaderVersion: widget.loaderVersion,
                    assetsID: meta["assets"]);

                uuid = config.uuid;

                config.createConfigFile();

                return meta;
              }

              WidgetsBinding.instance!.addPostFrameCallback((_) async {
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
                                  Instance instance = Instance(uuid);

                                  Uttily.javaCheckDialog(
                                      hasJava: () {
                                        if (widget.modLoaderID ==
                                            ModLoader.vanilla) {
                                          VanillaClient.createClient(
                                                  setState: setState,
                                                  meta: meta,
                                                  versionID: widget.version.id,
                                                  instance: instance)
                                              .whenComplete(() {
                                            finish = true;
                                            setState(() {});
                                          });
                                        } else if (widget.modLoaderID ==
                                            ModLoader.fabric) {
                                          FabricClient.createClient(
                                                  setState: setState,
                                                  meta: meta,
                                                  versionID: widget.version.id,
                                                  loaderVersion:
                                                      widget.loaderVersion,
                                                  instance: instance)
                                              .whenComplete(() {
                                            finish = true;
                                            setState(() {});
                                          });
                                        } else if (widget.modLoaderID ==
                                            ModLoader.forge) {
                                          ForgeClient.createClient(
                                                  setState: setState,
                                                  meta: meta,
                                                  gameVersionID:
                                                      widget.version.id,
                                                  forgeVersionID:
                                                      widget.loaderVersion,
                                                  instance: instance)
                                              .then((ForgeClientState state) =>
                                                  state.handlerState(
                                                      context, setState));
                                        }
                                      },
                                      allJavaVersions:
                                          instance.config.needJavaVersion);

                                  new_ = false;
                                }

                                if (infos.progress == 1.0 && finish) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(16.0),
                                    title:
                                        Text(I18n.format("gui.download.done")),
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
              });
            },
          ),
        ],
      );
    });
  }
}

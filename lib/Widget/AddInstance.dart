import 'package:rpmlauncher/Launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Launcher/VanillaClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
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
  final Future<void> Function(Instance)? onInstalled;

  const AddInstanceDialog(
      this.instanceName, this.version, this.modLoaderID, this.loaderVersion,
      {this.onInstalled});

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
          onPressed: () {
            finish = false;
            navigator.pop();
            navigator.push(
              PushTransitions(builder: (context) => HomePage()),
            );

            WidgetsBinding.instance!.addPostFrameCallback((_) async {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FutureBuilder(
                        future: widget.version.meta,
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Task(
                              meta: snapshot.data,
                              version: widget.version,
                              loader: widget.modLoaderID,
                              loaderVersion: widget.loaderVersion,
                              instanceName: _nameController.text,
                              onInstalled: widget.onInstalled,
                            );
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
  }
}

class Task extends StatefulWidget {
  final MinecraftMeta meta;
  final MCVersion version;
  final ModLoader loader;
  final String loaderVersion;
  final String instanceName;
  final Future<void> Function(Instance)? onInstalled;

  const Task(
      {Key? key,
      required this.meta,
      required this.version,
      required this.loader,
      required this.loaderVersion,
      required this.instanceName,
      this.onInstalled})
      : super(key: key);

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    nowEvent = I18n.format('version.list.downloading.ready');

    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      String uuid = Uuid().v4();
      InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          version: widget.version.id,
          loader: widget.loader.fixedString,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: widget.loaderVersion,
          assetsID: widget.meta["assets"]);
      Instance instance = Instance(uuid);
      config.createConfigFile();

      Future<void> whenComplete() async {
        if (widget.onInstalled != null) {
          nowEvent = I18n.format('version.list.downloading.handling');
          setState(() {});
          await widget.onInstalled!(instance);
        }
        finish = true;
        setState(() {});
      }

      Uttily.javaCheckDialog(
          hasJava: () {
            if (widget.loader == ModLoader.vanilla) {
              VanillaClient.createClient(
                      setState: setState,
                      meta: widget.meta,
                      versionID: widget.version.id,
                      instance: instance)
                  .whenComplete(() => whenComplete());
            } else if (widget.loader == ModLoader.fabric) {
              FabricClient.createClient(
                      setState: setState,
                      meta: widget.meta,
                      versionID: widget.version.id,
                      loaderVersion: widget.loaderVersion,
                      instance: instance)
                  .whenComplete(() => whenComplete());
            } else if (widget.loader == ModLoader.forge) {
              ForgeClient.createClient(
                      setState: setState,
                      meta: widget.meta,
                      gameVersionID: widget.version.id,
                      forgeVersionID: widget.loaderVersion,
                      instance: instance)
                  .then((ForgeClientState state) => state.handlerState(
                      context, setState, instance,
                      onSuccessful: widget.onInstalled));
            }
          },
          allJavaVersions: instance.config.needJavaVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(nowEvent, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              infos.progress == 0.0
                  ? LinearProgressIndicator()
                  : LinearProgressIndicator(
                      value: infos.progress,
                    ),
              Text("${(infos.progress * 100).toStringAsFixed(2)}%")
            ],
          ),
          actions: <Widget>[],
        ),
      );
    }
  }
}

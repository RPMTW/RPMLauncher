import 'package:rpmlauncher/launcher/Fabric/FabricClient.dart';
import 'package:rpmlauncher/launcher/Fabric/FabricServer.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeClient.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/launcher/Vanilla/VanillaClient.dart';
import 'package:rpmlauncher/launcher/Vanilla/VanillaServer.dart';
import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/screen/HomePage.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:uuid/uuid.dart';

import 'RWLLoading.dart';

class AddInstanceDialog extends StatefulWidget {
  final String instanceName;
  final MCVersion version;
  final ModLoader modLoaderID;
  final String? loaderVersion;
  final MinecraftSide side;
  final Future<void> Function(Instance)? onInstalled;

  const AddInstanceDialog(this.instanceName, this.version, this.modLoaderID,
      this.loaderVersion, this.side,
      {this.onInstalled});

  @override
  State<AddInstanceDialog> createState() => _AddInstanceDialogState();
}

class _AddInstanceDialogState extends State<AddInstanceDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.instanceName);
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
            installingState.finish = false;
            navigator.pop();
            navigator.push(
              PushTransitions(
                  builder: (context) => HomePage(
                        /// 依據玩家選擇的安裝檔類型到不同頁面 （客戶端或伺服器）
                        initialPage: widget.side.isClient ? 0 : 1,
                      )),
            );

            WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                              loaderVersion: widget.loaderVersion ?? "",
                              instanceName: _nameController.text,
                              side: widget.side,
                              onInstalled: widget.onInstalled,
                            );
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          } else {
                            return const Center(child: RWLLoading());
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
  final MinecraftSide side;
  final Future<void> Function(Instance)? onInstalled;

  const Task(
      {Key? key,
      required this.meta,
      required this.version,
      required this.loader,
      required this.loaderVersion,
      required this.instanceName,
      required this.side,
      this.onInstalled})
      : super(key: key);

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    installingState.nowEvent = I18n.format('version.list.downloading.ready');

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      String uuid = const Uuid().v4();
      InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          side: widget.side,
          version: widget.version.id,
          loader: widget.loader.fixedString,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: widget.loaderVersion,
          assetsID: widget.meta["assets"]);
      config.createConfigFile();
      Instance instance = Instance.fromUUID(uuid)!;

      Future<void> whenComplete() async {
        if (widget.onInstalled != null) {
          installingState.nowEvent =
              I18n.format('version.list.downloading.handling');
          setState(() {});
          await widget.onInstalled!(instance);
        }
        installingState.finish = true;
        setState(() {});
      }

      Util.javaCheckDialog(
          hasJava: () {
            if (widget.loader == ModLoader.vanilla) {
              if (widget.side == MinecraftSide.client) {
                VanillaClient.createClient(
                        setState: setState,
                        meta: widget.meta,
                        versionID: widget.version.id,
                        instance: instance)
                    .whenComplete(() => whenComplete());
              } else if (widget.side == MinecraftSide.server) {
                VanillaServer.createServer(
                        setState: setState,
                        meta: widget.meta,
                        versionID: widget.version.id,
                        instance: instance)
                    .whenComplete(() => whenComplete());
              }
            } else if (widget.loader == ModLoader.fabric) {
              if (widget.side == MinecraftSide.client) {
                FabricClient.createClient(
                        setState: setState,
                        meta: widget.meta,
                        versionID: widget.version.id,
                        loaderVersion: widget.loaderVersion,
                        instance: instance)
                    .whenComplete(() => whenComplete());
              } else if (widget.side == MinecraftSide.server) {
                FabricServer.createServer(
                        setState: setState,
                        meta: widget.meta,
                        versionID: widget.version.id,
                        loaderVersion: widget.loaderVersion,
                        instance: instance)
                    .whenComplete(() => whenComplete());
              }
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
    if (installingState.downloadInfos.progress == 1.0 &&
        installingState.finish) {
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
          title: Text(installingState.nowEvent, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              installingState.downloadInfos.progress == 0.0
                  ? const LinearProgressIndicator()
                  : LinearProgressIndicator(
                      value: installingState.downloadInfos.progress,
                    ),
              Text(
                  "${(installingState.downloadInfos.progress * 100).toStringAsFixed(2)}%")
            ],
          ),
        ),
      );
    }
  }
}

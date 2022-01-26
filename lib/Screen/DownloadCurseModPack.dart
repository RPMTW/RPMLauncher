import 'dart:convert';

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstallingState.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:uuid/uuid.dart';

import 'package:rpmlauncher/Utility/Data.dart';

class DownloadCurseModPack extends StatefulWidget {
  final Archive packArchive;
  final String modPackIconUrl;

  const DownloadCurseModPack(this.packArchive, this.modPackIconUrl);

  @override
  _DownloadCurseModPackState createState() => _DownloadCurseModPackState();
}

class _DownloadCurseModPackState extends State<DownloadCurseModPack> {
  late Map packMeta;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final archiveFile in widget.packArchive) {
      if (archiveFile.isFile && archiveFile.name == "manifest.json") {
        final data = archiveFile.content as List<int>;
        packMeta =
            json.decode(const Utf8Decoder(allowMalformed: true).convert(data));
        nameController.text = packMeta["name"];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: I18nText("modpack.add.title", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(I18n.format("edit.instance.homepage.instance.name"),
                  style:
                      const TextStyle(fontSize: 18, color: Colors.amberAccent)),
              Expanded(
                child: RPMTextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          I18nText(
            "modpack.name",
            args: {"name": packMeta["name"]},
          ),
          I18nText(
            "modpack.version",
            args: {
              "version": packMeta["version"] ?? I18n.format('gui.unknown')
            },
          ),
          I18nText(
            "modpack.version.game",
            args: {"game_version": packMeta["minecraft"]["version"]},
          ),
          I18nText(
            "modpack.author",
            args: {"author": packMeta["author"] ?? I18n.format('gui.unknown')},
          )
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
              navigator.push(
                  PushTransitions(builder: (context) => const HomePage()));

              String versionID = packMeta["minecraft"]["version"];

              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FutureBuilder<MinecraftMeta>(
                        future: Uttily.getVanillaVersionMeta(versionID),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Task(
                              meta: snapshot.data!,
                              versionID: versionID,
                              instanceName: nameController.text,
                              packMeta: packMeta,
                              packArchive: widget.packArchive,
                              modpackIconUrl: widget.modPackIconUrl,
                            );
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          } else {
                            return const Center(child: RWLLoading());
                          }
                        });
                  });
            })
      ],
    );
  }
}

class Task extends StatefulWidget {
  final MinecraftMeta meta;
  final String versionID;
  final String instanceName;
  final Map packMeta;
  final Archive packArchive;
  final String modpackIconUrl;

  const Task({
    required this.meta,
    required this.versionID,
    required this.packMeta,
    required this.instanceName,
    required this.packArchive,
    required this.modpackIconUrl,
  });

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    super.initState();
    installingState.finish = false;

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      String loaderID = widget.packMeta["minecraft"]["modLoaders"][0]["id"];
      bool isFabric = loaderID.startsWith(ModLoader.fabric.fixedString);
      String loaderVersionID = loaderID
          .split(
              "${isFabric ? ModLoader.fabric.fixedString : ModLoader.forge.fixedString}-")
          .join("");

      String uuid = const Uuid().v4();

      InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          side: MinecraftSide.client,
          version: widget.versionID,
          loader: (isFabric ? ModLoader.fabric : ModLoader.forge).fixedString,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: loaderVersionID,
          assetsID: widget.meta["assets"]);

      config.createConfigFile();

      if (widget.modpackIconUrl != "") {
        await RPMHttpClient().download(widget.modpackIconUrl,
            join(GameRepository.getInstanceRootDir().path, uuid, "icon.png"));
      }

      Uttily.javaCheckDialog(
          hasJava: () => CurseModPackClient.createClient(
              setState: setState,
              meta: widget.meta,
              versionID: widget.versionID,
              loaderVersion: loaderVersionID,
              instanceUUID: uuid,
              packMeta: widget.packMeta,
              packArchive: widget.packArchive),
          allJavaVersions: config.needJavaVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (installingState.finish &&
        installingState.downloadInfos.progress == 1.0) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format("gui.download.done")),
        actions: [
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
              LinearProgressIndicator(
                value: installingState.downloadInfos.progress,
              ),
              Text(
                  "${(installingState.downloadInfos.progress * 100).toStringAsFixed(2)}%")
            ],
          ),
          actions: <Widget>[],
        ),
      );
    }
  }
}

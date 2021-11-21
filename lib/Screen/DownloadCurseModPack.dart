import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';

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
  Directory instanceDir = GameRepository.getInstanceRootDir();

  @override
  void initState() {
    super.initState();
    for (final archiveFile in widget.packArchive) {
      if (archiveFile.isFile && archiveFile.name == "manifest.json") {
        final data = archiveFile.content as List<int>;
        packMeta = json.decode(Utf8Decoder(allowMalformed: true).convert(data));
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
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
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
          SizedBox(
            height: 12,
          ),
          I18nText(
            "modpack.name",
            args: {"name": packMeta["name"]},
          ),
          I18nText(
            "modpack.version",
            args: {"version": packMeta["version"]},
          ),
          I18nText(
            "modpack.version.game",
            args: {"game_version": packMeta["minecraft"]["version"]},
          ),
          I18nText(
            "modpack.author",
            args: {"author": packMeta["author"]},
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
              navigator.push(PushTransitions(builder: (context) => HomePage()));
              Future<Widget> handling() async {
                String loaderID = packMeta["minecraft"]["modLoaders"][0]["id"];
                bool isFabric =
                    loaderID.startsWith(ModLoaders.fabric.fixedString);

                String versionID = packMeta["minecraft"]["version"];
                String loaderVersionID = loaderID
                    .split(
                        "${isFabric ? ModLoaders.fabric.fixedString : ModLoaders.forge.fixedString}-")
                    .join("");

                final url = Uri.parse(
                    await CurseForgeHandler.getMCVersionMetaUrl(versionID));
                Response response = await get(url);
                MinecraftMeta meta = MinecraftMeta(jsonDecode(response.body));

                String uuid = Uuid().v4();

                InstanceConfig config = InstanceConfig(
                    uuid: uuid,
                    name: nameController.text,
                    version: versionID,
                    loader: (isFabric ? ModLoaders.fabric : ModLoaders.forge)
                        .fixedString,
                    javaVersion: meta.containsKey('javaVersion')
                        ? meta["javaVersion"]["majorVersion"]
                        : 8,
                    loaderVersion: loaderVersionID,
                    assetsID: meta["assets"]);

                config.createConfigFile();

                if (widget.modPackIconUrl != "") {
                  await http
                      .get(Uri.parse(widget.modPackIconUrl))
                      .then((response) async {
                    await File(
                            join(instanceDir.absolute.path, uuid, "icon.png"))
                        .writeAsBytes(response.bodyBytes);
                  });
                }

                return Task(
                    meta: meta,
                    versionID: versionID,
                    loaderVersionID: loaderVersionID,
                    instanceUUID: uuid,
                    packMeta: packMeta,
                    packArchive: widget.packArchive);
              }

              showDialog(
                  context: context,
                  builder: (context) {
                    return FutureBuilder(
                        future: handling(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data;
                          } else {
                            return RWLLoading();
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
  final String loaderVersionID;
  final String instanceUUID;
  final Map packMeta;
  final Archive packArchive;

  const Task({
    required this.meta,
    required this.versionID,
    required this.loaderVersionID,
    required this.instanceUUID,
    required this.packMeta,
    required this.packArchive,
  });

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    super.initState();
    Uttily.javaCheckDialog(
        hasJava: () => CurseModPackClient.createClient(
            setState: setState,
            meta: widget.meta,
            versionID: widget.versionID,
            loaderVersion: widget.loaderVersionID,
            instanceUUID: widget.instanceUUID,
            packMeta: widget.packMeta,
            packArchive: widget.packArchive),
        allJavaVersions: Instance(widget.instanceUUID).config.needJavaVersion);
  }

  @override
  Widget build(BuildContext context) {
    if (finish && infos.progress == 1.0) {
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
          title: Text(nowEvent, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
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

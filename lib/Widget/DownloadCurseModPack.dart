import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';

class DownloadCurseModPack extends StatefulWidget {
  late Archive PackArchive;
  late var ModPackIconUrl;

  DownloadCurseModPack(Archive PackArchive_, ModPackIconUrl_) {
    PackArchive = PackArchive_;
    ModPackIconUrl = ModPackIconUrl_;
  }

  @override
  DownloadCurseModPack_ createState() => DownloadCurseModPack_();
}

class DownloadCurseModPack_ extends State<DownloadCurseModPack> {
  late Map PackMeta;
  Color BorderColour = Colors.red;
  TextEditingController NameController = TextEditingController();
  Directory InstanceDir = GameRepository.getInstanceRootDir();

  @override
  void initState() {
    super.initState();
    for (final archiveFile in widget.PackArchive) {
      if (archiveFile.isFile && archiveFile.name == "manifest.json") {
        final data = archiveFile.content as List<int>;
        PackMeta = json.decode(Utf8Decoder(allowMalformed: true).convert(data));
        NameController.text = PackMeta["name"];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text("新增模組包", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(i18n.format("edit.instance.homepage.instance.name"),
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
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
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    if (!utility.ValidInstanceName(value)) {
                      BorderColour = Colors.red;
                    } else {
                      BorderColour = Colors.lightBlue;
                    }
                    setState(() {});
                  },
                ),
              )
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Text("模組包名稱: ${PackMeta["name"]}"),
          Text("模組包版本: ${PackMeta["version"]}"),
          Text("模組包遊戲版本: ${PackMeta["minecraft"]["version"]}"),
          Text("模組包作者: ${PackMeta["author"]}"),
        ],
      ),
      actions: [
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
              String LoaderID = PackMeta["minecraft"]["modLoaders"][0]["id"];
              bool isFabric = LoaderID.startsWith(ModLoaders.Fabric.fixedString);

              String VersionID = PackMeta["minecraft"]["version"];
              String LoaderVersionID = LoaderID.split(
                      "${isFabric ? ModLoaders.Fabric : ModLoaders.Forge}-")
                  .join("");

              final url = Uri.parse(
                  await CurseForgeHandler.getMCVersionMetaUrl(VersionID));
              Response response = await get(url);
              Map<String, dynamic> Meta = jsonDecode(response.body);
              var NewInstanceConfig = {
                "name": NameController.text,
                "version": VersionID,
                "loader": (isFabric ? ModLoaders.Fabric : ModLoaders.Forge).fixedString,
                "java_version": Meta.containsKey('javaVersion')
                    ? Meta["javaVersion"]["majorVersion"]
                    : 8,
                "loader_version": LoaderVersionID,
                'play_time': 0
              };
              File(join(InstanceDir.absolute.path, NameController.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));

              if (widget.ModPackIconUrl != "") {
                await http
                    .get(Uri.parse(widget.ModPackIconUrl))
                    .then((response) async {
                  await File(join(InstanceDir.absolute.path,
                          NameController.text, "icon.png"))
                      .writeAsBytes(response.bodyBytes);
                });
              }

              navigator.pop();
              navigator.push(PushTransitions(builder: (context) => HomePage()));

              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Task(Meta, VersionID, LoaderVersionID,
                        NameController.text, PackMeta, widget.PackArchive);
                  });
            })
      ],
    );
  }
}

class Task extends StatefulWidget {
  late var Meta;
  late var VersionID;
  late var LoaderVersionID;
  late var InstanceDirName;
  late var PackMeta;
  late var PackArchive;

  Task(Meta_, VersionID_, LoaderVersionID_, InstanceDirName_, PackMeta_,
      PackArchive_) {
    Meta = Meta_;
    VersionID = VersionID_;
    LoaderVersionID = LoaderVersionID_;
    InstanceDirName = InstanceDirName_;
    PackMeta = PackMeta_;
    PackArchive = PackArchive_;
  }

  @override
  Task_ createState() => Task_();
}

class Task_ extends State<Task> {
  @override
  void initState() {
    super.initState();
    CurseModPackClient.createClient(
        setState: setState,
        Meta: widget.Meta,
        VersionID: widget.VersionID,
        LoaderVersion: widget.LoaderVersionID,
        InstanceDirName: widget.InstanceDirName,
        PackMeta: widget.PackMeta,
        PackArchive: widget.PackArchive);
  }

  @override
  Widget build(BuildContext context) {
    if (finish && infos.progress == 1) {
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
          contentPadding: const EdgeInsets.all(16.0),
          title: Text(NowEvent, textAlign: TextAlign.center),
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

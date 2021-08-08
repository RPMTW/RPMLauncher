import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/MCLauncher/Fabric/FabricClient.dart';
import 'package:RPMLauncher/MCLauncher/GameRepository.dart';
import 'package:RPMLauncher/Mod/CurseForge/Handler.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class DownloadCurseModPack extends StatefulWidget {
  late Archive PackArchive;

  DownloadCurseModPack(Archive PackArchive_) {
    PackArchive = PackArchive_;
  }

  @override
  DownloadCurseModPack_ createState() => DownloadCurseModPack_(PackArchive);
}

class DownloadCurseModPack_ extends State<DownloadCurseModPack> {
  late Archive PackArchive;
  late Map PackMeta;
  Color BorderColour = Colors.lightBlue;
  TextEditingController NameController = TextEditingController();
  Directory InstanceDir = GameRepository.getInstanceRootDir();

  DownloadCurseModPack_(Archive PackArchive_) {
    PackArchive = PackArchive_;
  }

  @override
  void initState() {
    super.initState();

    for (final archiveFile in PackArchive) {
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
              Text(i18n.Format("edit.instance.homepage.instance.name"),
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
                    if (value == "" ||
                        File(join(InstanceDir.absolute.path, value,
                                "instance.json"))
                            .existsSync()) {
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
          child: Text(i18n.Format("gui.cancel")),
          onPressed: () {
            BorderColour = Colors.lightBlue;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(i18n.Format("gui.confirm")),
          onPressed: () async {
            String LoaderID = PackMeta["minecraft"]["modLoaders"][0]["id"];
            bool isFabric = LoaderID.startsWith(ModLoader().Fabric);
            bool isForge = LoaderID.startsWith(ModLoader().Forge);

            if (isFabric) {
              String VersionID = PackMeta["minecraft"]["version"];
              String LoaderVersionID =
                  LoaderID.split("${ModLoader().Fabric}-").join("");

              final url = Uri.parse(
                  await CurseForgeHandler.getMCVersionMetaUrl(VersionID));
              Response response = await get(url);
              Map<String, dynamic> Meta = jsonDecode(response.body);
              var NewInstanceConfig = {
                "name": NameController.text,
                "version": VersionID,
                "loader": ModLoader().Fabric,
                "java_version": Meta["javaVersion"]["majorVersion"],
                "loader_version": LoaderVersionID
              };
              File(join(InstanceDir.absolute.path, NameController.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));

              FabricClient.createClient(
                  setState: setState,
                  Meta: Meta,
                  VersionID: VersionID,
                  LoaderVersion: LoaderVersionID);
            } else if (isForge) {
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(i18n.Format("gui.error.info")),
                        content: Text(i18n.Format(
                            "version.mod.loader.forge.support.error")),
                        actions: <Widget>[
                          TextButton(
                            child: Text(i18n.Format("gui.ok")),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          )
                        ]);
                  });
            }
          },
        )
      ],
    );
  }
}

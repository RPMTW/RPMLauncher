import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Screen/CurseForgeMod.dart';
import 'package:rpmlauncher/Screen/ModrinthMod.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class ModSourceSelection_ extends State<ModSourceSelection> {
  late String InstanceDirName;
  late Directory ModDir = InstanceRepository.getModRootDir(InstanceDirName);

  ModSourceSelection_(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      scrollable: true,
      title: Text(i18n.format("source.mod.title"), textAlign: TextAlign.center),
      content: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.deepPurpleAccent,
                onPressed: () async {
                  final files = await FileSelectorPlatform.instance
                      .openFiles(acceptedTypeGroups: [
                    XTypeGroup(label: 'Jar', mimeTypes: [
                      'application/zip',
                      'application/java-archive',
                    ], extensions: [
                      'jar'
                    ]),
                  ]);
                  if (files.length == 0) return;
                  for (XFile file in files) {
                    File(file.path)
                        .copySync(join(ModDir.absolute.path, file.name));
                  }
                  Navigator.pop(context);
                },
                child: Icon(Icons.computer),
              ),
              SizedBox(
                height: 12,
              ),
              Text(i18n.format("source.local"))
            ],
          ),
          SizedBox(
            width: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) => CurseForgeMod(InstanceDirName));
                  },
                  child: Image.asset("images/CurseForge.png")),
              SizedBox(
                height: 12,
              ),
              Text(i18n.format("source.curseforge")),
            ],
          ),
          SizedBox(
            width: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.transparent,
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (context) => ModrinthMod(InstanceDirName));
                },
                child: Image.asset("images/Modrinth.png"),
              ),
              SizedBox(
                height: 12,
              ),
              Text(i18n.format("source.modrinth"))
            ],
          )
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: i18n.format("gui.close"),
        )
      ],
    ));
  }
}

class ModSourceSelection extends StatefulWidget {
  late String InstanceDirName;

  ModSourceSelection(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  ModSourceSelection_ createState() => ModSourceSelection_(InstanceDirName);
}

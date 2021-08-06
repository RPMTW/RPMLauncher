import 'dart:io';

import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Screen/CurseForgeMod.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class ModSourceSelection_ extends State<ModSourceSelection> {
  late String InstanceDirName;
  late Directory ModDir = InstanceRepository.getInstanceModRootDir(InstanceDirName);

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
      title: Text("請選擇模組來源", textAlign: TextAlign.center),
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
                    XTypeGroup(label: '模組Jar檔案', mimeTypes: [
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
              Text("本機檔案")
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
                    // Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (context) => CurseForgeMod(InstanceDirName));
                  },
                  child: Image.asset("images/CurseForge.png")),
              SizedBox(
                height: 12,
              ),
              Text("CurseForge"),
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

                },
                child:Image.asset("images/Modrinth.png"),
              ),
              SizedBox(
                height: 12,
              ),
              Text("Modrinth")
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
          tooltip: i18n.Format("gui.close"),
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

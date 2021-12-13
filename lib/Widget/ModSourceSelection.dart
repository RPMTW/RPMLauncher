import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/ModInfo.dart';
import 'package:rpmlauncher/Screen/CurseForgeMod.dart';
import 'package:rpmlauncher/Screen/ModrinthMod.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class _ModSourceSelectionState extends State<ModSourceSelection> {
  Directory get modDir => InstanceRepository.getModRootDir(widget.instanceUUID);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      scrollable: true,
      title: Text(I18n.format("source.mod.title"), textAlign: TextAlign.center),
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
                  if (files.isEmpty) return;
                  if (modDir.existsSync()) {
                    for (XFile file in files) {
                      File(file.path)
                          .copySync(join(modDir.absolute.path, file.name));
                    }
                  }

                  Navigator.pop(context);
                },
                child: Icon(Icons.computer),
              ),
              SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.local"))
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
                        builder: (context) => CurseForgeMod(
                            widget.instanceUUID, widget.modInfos));
                  },
                  child: Image.asset("assets/images/CurseForge.png")),
              SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.curseforge")),
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
                      builder: (context) =>
                          ModrinthMod(instanceUUID: widget.instanceUUID));
                },
                child: Image.asset("assets/images/Modrinth.png"),
              ),
              SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.modrinth"))
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
          tooltip: I18n.format("gui.close"),
        )
      ],
    ));
  }
}

class ModSourceSelection extends StatefulWidget {
  final String instanceUUID;
  final List<ModInfo> modInfos;

  const ModSourceSelection(this.instanceUUID, this.modInfos);

  @override
  _ModSourceSelectionState createState() => _ModSourceSelectionState();
}

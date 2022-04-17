import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/Game/ModInfo.dart';
import 'package:rpmlauncher/screen/CurseForgeMod.dart';
import 'package:rpmlauncher/screen/ModrinthMod.dart';
import 'package:rpmlauncher/util/I18n.dart';
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
                  final FilePickerResult? result =
                      await FilePicker.platform.pickFiles(allowedExtensions: [
                    'application/zip',
                    'application/java-archive',
                    'jar',
                  ], allowMultiple: true);

                  if (result == null || result.files.isEmpty) return;

                  if (modDir.existsSync()) {
                    for (PlatformFile file in result.files) {
                      File(file.path!)
                          .copySync(join(modDir.absolute.path, file.name));
                    }
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Icon(Icons.computer),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.local"))
            ],
          ),
          const SizedBox(
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
              const SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.curseforge")),
            ],
          ),
          const SizedBox(
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
              const SizedBox(
                height: 12,
              ),
              Text(I18n.format("source.modrinth"))
            ],
          )
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close_sharp),
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
  State<ModSourceSelection> createState() => _ModSourceSelectionState();
}

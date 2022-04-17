import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class _ShaderpackSourceSelectionState extends State<ShaderpackSourceSelection> {
  late Directory shaderpackDir =
      InstanceRepository.getShaderpackRootDir(widget.instanceUUID);

  _ShaderpackSourceSelectionState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      scrollable: true,
      title: I18nText("edit.instance.shaderpack.add.source",
          textAlign: TextAlign.center),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              FloatingActionButton(
                backgroundColor: Colors.deepPurpleAccent,
                onPressed: () async {
                  final FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                          dialogTitle:
                              I18n.format('edit.instance.shaderpack.file'),
                          allowMultiple: true,
                          allowedExtensions: ['zip']);

                  if (result == null || result.files.isEmpty) {
                    return;
                  }

                  for (PlatformFile file in result.files) {
                    File(file.path!)
                        .copySync(join(shaderpackDir.absolute.path, file.name));
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

class ShaderpackSourceSelection extends StatefulWidget {
  final String instanceUUID;

  const ShaderpackSourceSelection(this.instanceUUID);

  @override
  State<ShaderpackSourceSelection> createState() =>
      _ShaderpackSourceSelectionState();
}

import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class _ShaderpackSourceSelectionState extends State<ShaderpackSourceSelection> {
  late Directory shaderpackDir =
      InstanceRepository.getShaderpackRootDir(widget.instanceDirName);

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
      title: Text("請選擇光影來源", textAlign: TextAlign.center),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              FloatingActionButton(
                backgroundColor: Colors.deepPurpleAccent,
                onPressed: () async {
                  final files = await FileSelectorPlatform.instance
                      .openFiles(acceptedTypeGroups: [
                    XTypeGroup(
                        label: '光影檔案', mimeTypes: [], extensions: ['zip']),
                  ]);
                  if (files.isEmpty) return;
                  for (XFile file in files) {
                    File(file.path)
                        .copySync(join(shaderpackDir.absolute.path, file.name));
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

class ShaderpackSourceSelection extends StatefulWidget {
  final String instanceDirName;

  const ShaderpackSourceSelection(this.instanceDirName);

  @override
  _ShaderpackSourceSelectionState createState() => _ShaderpackSourceSelectionState();
}

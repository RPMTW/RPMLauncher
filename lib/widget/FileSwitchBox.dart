import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/I18n.dart';

class FileSwitchBox extends StatefulWidget {
  final File file;
  const FileSwitchBox({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<FileSwitchBox> createState() => _FileSwitchBoxState();
}

class _FileSwitchBoxState extends State<FileSwitchBox> {
  late File file;
  bool get modSwitch => !file.path.endsWith(".disable");

  @override
  void initState() {
    file = widget.file;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          modSwitch ? I18n.format('gui.disable') : I18n.format('gui.enable'),
      child: Checkbox(
          value: modSwitch,
          activeColor: Colors.blueAccent,
          onChanged: (value) async {
            try {
              if (modSwitch) {
                String name = "${file.absolute.path}.disable";
                await file.rename(name);
                file = File(name);
                setState(() {});
              } else {
                String name = file.absolute.path.split(".disable")[0];
                await file.rename(name);
                file = File(name);
                setState(() {});
              }
            } on FileSystemException {}
          }),
    );
  }
}

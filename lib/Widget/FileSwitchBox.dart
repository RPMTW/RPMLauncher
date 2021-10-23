import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class FileSwitchBox extends StatelessWidget {
  File file;
  FileSwitchBox({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool modSwitch = !file.path.endsWith(".disable");

    return StatefulBuilder(builder: (context, setSwitchState) {
      return Tooltip(
        message:
            modSwitch ? I18n.format('gui.disable') : I18n.format('gui.enable'),
        child: Checkbox(
            value: modSwitch,
            activeColor: Colors.blueAccent,
            onChanged: (value) {
              if (modSwitch) {
                modSwitch = false;
                String name = file.absolute.path + ".disable";
                file.rename(name);
                file = File(name);
                setSwitchState(() {});
              } else {
                modSwitch = true;
                String name = file.absolute.path.split(".disable")[0];
                file.rename(name);
                file = File(name);
                setSwitchState(() {});
              }
            }),
      );
    });
  }
}

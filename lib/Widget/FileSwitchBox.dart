import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

class FileSwitchBox extends StatelessWidget {
  File file;
  FileSwitchBox({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool ModSwitch = !file.path.endsWith(".disable");

    return StatefulBuilder(builder: (context, setSwitchState) {
      return Tooltip(
        message:
            ModSwitch ? i18n.format('gui.disable') : i18n.format('gui.enable'),
        child: Checkbox(
            value: ModSwitch,
            activeColor: Colors.blueAccent,
            onChanged: (value) {
              if (ModSwitch) {
                ModSwitch = false;
                String Name = file.absolute.path + ".disable";
                file.rename(Name);
                file = File(Name);
                setSwitchState(() {});
              } else {
                ModSwitch = true;
                String Name = file.absolute.path.split(".disable")[0];
                file.rename(Name);
                file = File(Name);
                setSwitchState(() {});
              }
            }),
      );
    });
  }
}

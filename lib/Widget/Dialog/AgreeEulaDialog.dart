import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/IO/Properties.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/LinkText.dart';

class AgreeEulaDialog extends StatelessWidget {
  const AgreeEulaDialog({
    Key? key,
    required this.properties,
    required this.eulaFile,
  }) : super(key: key);

  final Properties properties;
  final File eulaFile;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText.tipsInfoText(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          I18nText("launcher.server.eula.title"),
          SizedBox(
            height: 12,
          ),
          LinkText(
              link: "https://www.minecraft.net/en-us/eula",
              text: I18n.format("launcher.server.eula"))
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            properties['eula'] = true.toString();
            eulaFile.writeAsStringSync(Properties.encode(properties));
            Navigator.pop(context);
          },
          child: Text(I18n.format('gui.agree')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context)
                .push(PushTransitions(builder: (context) => HomePage()));
          },
          child: Text(I18n.format('gui.disagree')),
        )
      ],
    );
  }
}

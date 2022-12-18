import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/IO/Properties.dart';
import 'package:rpmlauncher/ui/screen/home_page.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/LinkText.dart';

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
          const SizedBox(
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
            Navigator.pushNamed(context, HomePage.route);
          },
          child: Text(I18n.format('gui.disagree')),
        )
      ],
    );
  }
}

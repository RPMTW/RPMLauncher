import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/Process.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';

class UpdaterDialog extends StatelessWidget {
  VersionInfo info;
  UpdaterDialog({
    Key? key,
    required this.info,
  }) : super(key: key);

  final TextStyle _title = const TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: I18nText("updater.title", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            I18nText(
              'updater.tips',
              style: const TextStyle(fontSize: 18),
            ),
            const Divider(),
            I18nText(
              "updater.latest",
              args: {"version": info.version!, "buildID": info.buildID!},
              style: _title,
            ),
            const Divider(),
            I18nText(
              "updater.current",
              args: {
                "version": LauncherInfo.getVersion(),
                "buildID": LauncherInfo.getBuildID().toString()
              },
              style: _title,
            ),
            const Divider(),
            I18nText(
              "updater.changelog",
              style: _title,
            ),
            const Divider(),
            SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.height / 3,
                child: ListView(
                  shrinkWrap: true,
                  children: info.changelogWidgets,
                ))
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: I18nText("updater.tips.not")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (Platform.isMacOS) {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(I18n.format('gui.tips.info')),
                            content: I18nText("updater.unsupport_macos"),
                            actions: const [OkClose()],
                          ));
                } else {
                  if (Platform.isLinux) {
                    if (LauncherInfo.isSnapcraftApp) {
                      xdgOpen(
                          "snap://rpmlauncher?channel=latest/${launcherConfig.updateChannel == VersionTypes.stable ? "stable" : "beta"}");
                    } else if (LauncherInfo.isFlatpakApp) {
                      Util.openUri(
                          "https://flathub.org/apps/details/ga.rpmtw.rpmlauncher");
                    } else {
                      Updater.download(info);
                    }
                  } else {
                    Updater.download(info);
                  }
                }
              },
              child: I18nText("updater.tips.yes"))
        ]);
  }
}

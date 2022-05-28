import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';

import 'package:rpmlauncher/util/data.dart';

class AboutScreenState extends State<AboutScreen> {
  final TextStyle title_ = const TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.format("homepage.about")),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 12,
          ),
          Text(I18n.format('about.dev.frame'),
              style: title_, textAlign: TextAlign.center),
          Text(I18n.format('about.dev.language'),
              style: title_, textAlign: TextAlign.center),
          Text(
              "${I18n.format("about.version.title")} ${LauncherInfo.getFullVersion()}",
              style: title_,
              textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${I18n.format("about.version.type")}  ",
                  style: title_, textAlign: TextAlign.center),
              LauncherInfo.getVersionTypeText(),
            ],
          ),
          Text(I18n.format('about.link'),
              style: const TextStyle(fontSize: 25, color: Colors.red),
              textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Util.openUri(LauncherInfo.homePageUrl);
                },
                icon: const Icon(LineIcons.home),
                tooltip: I18n.format('homepage.website'),
              ),
              IconButton(
                onPressed: () {
                  Util.openUri(LauncherInfo.githubRepoUrl);
                },
                icon: const Icon(LineIcons.github),
                tooltip: I18n.format('about.github'),
              ),
              IconButton(
                onPressed: () {
                  Util.openUri(LauncherInfo.discordUrl);
                },
                icon: const Icon(LineIcons.discord),
                tooltip: I18n.format('about.discord'),
              ),
              IconButton(
                icon: const Icon(Icons.book_outlined),
                onPressed: () {
                  showLicensePage(
                    applicationName: LauncherInfo.getUpperCaseName(),
                    applicationVersion: LauncherInfo.getFullVersion(),
                    applicationIcon: Image.asset("assets/images/Logo.png"),
                    context: context,
                  );
                },
                tooltip: I18n.format("about.license.show"),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
        ],
      ),
      persistentFooterButtons: const [
        Center(
          child:
              Text("Copyright © The RPMTW Team 2021-2022 All Right Reserved."),
        )
      ],
    );
  }
}

class AboutScreen extends StatefulWidget {
  @override
  AboutScreenState createState() => AboutScreenState();
}

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';

class AboutScreenState extends State<AboutScreen> {
  final TextStyle title_ = TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.format("homepage.about")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 12,
          ),
          Text(I18n.format('about.dev.frame'),
              style: title_, textAlign: TextAlign.center),
          Text(I18n.format('about.dev.language'),
              style: title_, textAlign: TextAlign.center),
          Text(
              "${I18n.format("about.version.title")} ${LauncherInfo.getVersion()}",
              style: title_,
              textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(I18n.format("about.version.type") + "  ",
                  style: title_, textAlign: TextAlign.center),
              LauncherInfo.getVersionTypeText(),
            ],
          ),
          Text(
              "${I18n.format("about.version.code")} ${LauncherInfo.getVersionCode()}",
              style: title_,
              textAlign: TextAlign.center),
          SizedBox(
            height: 25,
          ),
          Text(I18n.format('about.link'),
              style: TextStyle(fontSize: 25, color: Colors.red),
              textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await Uttily.openUrl(LauncherInfo.homePageUrl);
                },
                icon: Icon(LineIcons.home),
                tooltip: I18n.format('homepage.website'),
              ),
              IconButton(
                onPressed: () async {
                  await Uttily.openUrl(LauncherInfo.githubRepoUrl);
                },
                icon: Icon(LineIcons.github),
                tooltip: I18n.format('about.github'),
              ),
              IconButton(
                icon: Icon(Icons.book_outlined),
                onPressed: () {
                  showLicensePage(
                    applicationName: LauncherInfo.getUpperCaseName(),
                    applicationVersion: LauncherInfo.getVersion(),
                    applicationIcon: Image.asset("images/Logo.png"),
                    context: context,
                  );
                },
                tooltip: I18n.format("about.license.show"),
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
        ],
      ),
      persistentFooterButtons: [
        Center(
          child:
              Text("Copyright © The RPMTW Team 2021-2021 All Right Reserved."),
        )
      ],
    );
  }
}

class AboutScreen extends StatefulWidget {
  @override
  AboutScreenState createState() => AboutScreenState();
}

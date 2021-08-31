import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';

class AboutScreen_ extends State<AboutScreen> {
  TextStyle title_ = TextStyle(fontSize: 20);

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(i18n.Format("homepage.about")),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n.Format("gui.back"),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new LauncherHome()),
            );
          },
        ),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 12,
          ),
          Text(i18n.Format('about.dev.frame'),
              style: title_, textAlign: TextAlign.center),
          Text(i18n.Format('about.dev.language'),
              style: title_, textAlign: TextAlign.center),
          Text(
              "${i18n.Format("about.version.title")} ${LauncherInfo.getVersion()}",
              style: title_,
              textAlign: TextAlign.center),
          SizedBox(
            height: 25,
          ),
          Text(i18n.Format('about.link'),
              style: TextStyle(fontSize: 25, color: Colors.red),
              textAlign: TextAlign.center),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await utility.OpenUrl(LauncherInfo.HomePageUrl);
                },
                icon: Icon(LineIcons.home),
                tooltip: i18n.Format('homepage.website'),
              ),
              IconButton(
                onPressed: () async {
                  await utility.OpenUrl(LauncherInfo.GithubRepoUrl);
                },
                icon: Icon(LineIcons.github),
                tooltip: i18n.Format('about.github'),
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
                tooltip: i18n.Format("about.license.show"),
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
          child: Text(
              "Copyright © RPMLauncher And RPMTW Team 2021-2021  All Right Reserved."),
        )
      ],
    );
  }
}

class AboutScreen extends StatefulWidget {
  @override
  AboutScreen_ createState() => AboutScreen_();
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/InstanceView.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/Dialog/QuickSetup.dart';
import 'package:rpmlauncher/Widget/Dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:xml/xml.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (Config.getValue('init') == false && mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => QuickSetup());
      } else {
        Updater.checkForUpdate(Updater.fromConfig()).then((VersionInfo info) {
          if (info.needUpdate && mounted) {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => UpdaterDialog(info: info));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 300,
          leading: RowScrollView(
            center: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Tooltip(
                  message: I18n.format("homepage.website"),
                  waitDuration: Duration(milliseconds: 300),
                  child: IconButton(
                    onPressed: () {
                      Uttily.openUri(LauncherInfo.homePageUrl);
                    },
                    icon: Image.asset("assets/images/Logo.png", scale: 4),
                  ),
                ),
                Tooltip(
                  message: I18n.format("gui.settings"),
                  child: IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      navigator.pushNamed(SettingScreen.route);
                    },
                  ),
                ),
                Tooltip(
                  message: I18n.format("homepage.data.folder.open"),
                  child: IconButton(
                    icon: Icon(Icons.folder),
                    onPressed: () {
                      Uttily.openFileManager(RPMPath.currentDataHome);
                    },
                  ),
                ),
                Tooltip(
                  message: I18n.format("homepage.about"),
                  child: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PushTransitions(builder: (context) => AboutScreen()),
                      );
                    },
                  ),
                ),
                Tooltip(
                  message: I18n.format("homepage.update"),
                  child: IconButton(
                    icon: Icon(Icons.upgrade_outlined),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => FutureBuilder<VersionInfo>(
                              future:
                                  Updater.checkForUpdate(Updater.fromConfig()),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  VersionInfo info = snapshot.data!;
                                  if (info.needUpdate) {
                                    return UpdaterDialog(info: snapshot.data!);
                                  } else {
                                    return AlertDialog(
                                      title: I18nText.tipsInfoText(),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          I18nText("updater.check.none"),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Icon(Icons.done_outlined, size: 50)
                                        ],
                                      ),
                                      actions: [OkClose()],
                                    );
                                  }
                                } else {
                                  return AlertDialog(
                                    title: I18nText.tipsInfoText(),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        I18nText("updater.check.checking"),
                                        RWLLoading()
                                      ],
                                    ),
                                  );
                                }
                              }));
                    },
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            LauncherInfo.getUpperCaseName(),
          ),
          bottom: TabBar(tabs: [
            Tab(
                icon: Icon(Icons.sports_esports),
                text: I18n.format('homepage.tabs.instance')),
            Tab(
                icon: Icon(Icons.notifications),
                text: I18n.format('homepage.tabs.news'))
          ]),
          actions: [
            IconButton(
              icon: Icon(Icons.bug_report),
              onPressed: () => LauncherInfo.feedback(context),
              tooltip: I18n.format("homepage.bug_report"),
            ),
            IconButton(
              icon: Icon(Icons.manage_accounts),
              onPressed: () {
                navigator.pushNamed(AccountScreen.route);
              },
              tooltip: I18n.format("account.title"),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            InstanceView(),
            FutureBuilder(
              future: RPMHttpClient().get(minecraftNewsRSS),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  Response response = snapshot.data;
                  XmlDocument xmlDocument = XmlDocument.parse(response.data);
                  MinecraftNews news = MinecraftNews.fromXml(xmlDocument);
                  return MinecraftNewsView(news: news);
                } else {
                  return RWLLoading();
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () {
            Navigator.push(context,
                PushTransitions(builder: (context) => VersionSelection()));
          },
          tooltip: I18n.format("version.list.instance.add"),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

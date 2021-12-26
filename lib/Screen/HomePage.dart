import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/About.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
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
import 'package:rpmlauncher/Widget/AccountManageAction.dart';
import 'package:rpmlauncher/Widget/Dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/NewFeaturesWidget.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:xml/xml.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';
  final int initialPage;

  const HomePage({Key? key, this.initialPage = 0}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initialPage,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 300,
          leading: RowScrollView(
            center: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: I18n.format("homepage.website"),
                  onPressed: () {
                    Uttily.openUri(LauncherInfo.homePageUrl);
                  },
                  icon: Image.asset("assets/images/Logo.png", scale: 4),
                ),
                IconButton(
                  tooltip: I18n.format("gui.settings"),
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    navigator.pushNamed(SettingScreen.route);
                  },
                ),
                IconButton(
                  tooltip: I18n.format("homepage.data.folder.open"),
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    Uttily.openFileManager(RPMPath.currentDataHome);
                  },
                ),
                IconButton(
                  tooltip: I18n.format("homepage.about"),
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PushTransitions(builder: (context) => AboutScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.bug_report),
                  onPressed: () => LauncherInfo.feedback(context),
                  tooltip: I18n.format("homepage.bug_report"),
                ),
                IconButton(
                  icon: Icon(Icons.change_circle),
                  tooltip: I18n.format("homepage.update"),
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
                icon: NewFeaturesWidget(child: Icon(LineIcons.server)),
                text: I18n.format('homepage.tabs.server')),
            Tab(
                icon: Icon(Icons.notifications),
                text: I18n.format('homepage.tabs.news')),
          ]),
          actions: [
            AccountManageButton(),
          ],
        ),
        body: TabBarView(
          children: [
            InstanceView(side: MinecraftSide.client),
            InstanceView(side: MinecraftSide.server),
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
        floatingActionButton: _FloatingAction(),
      ),
    );
  }
}

class _FloatingAction extends StatefulWidget {
  const _FloatingAction({
    Key? key,
  }) : super(key: key);

  @override
  State<_FloatingAction> createState() => _FloatingActionState();
}

class _FloatingActionState extends State<_FloatingAction> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      DefaultTabController.of(context)?.addListener(() {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int index = DefaultTabController.of(context)?.index ?? 0;
    if (index == 0) {
      return FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
              context,
              PushTransitions(
                  builder: (context) => VersionSelection(
                        side: MinecraftSide.client,
                      )));
        },
        tooltip: I18n.format("version.list.instance.add"),
        child: Icon(Icons.add),
      );
    } else if (index == 1) {
      return FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
              context,
              PushTransitions(
                  builder: (context) => VersionSelection(
                        side: MinecraftSide.server,
                      )));
        },
        tooltip: I18n.format("version.list.instance.add.server"),
        child: Icon(Icons.add),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

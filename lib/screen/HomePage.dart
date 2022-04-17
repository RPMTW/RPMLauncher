import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/screen/About.dart';
import 'package:rpmlauncher/screen/Settings.dart';
import 'package:rpmlauncher/screen/VersionSelection.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/Data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/RPMPath.dart';
import 'package:rpmlauncher/util/Updater.dart';
import 'package:rpmlauncher/util/Utility.dart';
import 'package:rpmlauncher/view/InstanceView.dart';
import 'package:rpmlauncher/view/MinecraftNewsView.dart';
import 'package:rpmlauncher/view/RowScrollView.dart';
import 'package:rpmlauncher/widget/AccountManageAction.dart';
import 'package:rpmlauncher/widget/dialog/QuickSetup.dart';
import 'package:rpmlauncher/widget/dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/widget/rpmtw_design/NewFeaturesWidget.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:xml/xml.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';
  final int initialPage;

  const HomePage({Key? key, this.initialPage = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (Config.getValue('init') == false && mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const QuickSetup());
      } else {
        Updater.checkForUpdate(Updater.fromConfig()).then((VersionInfo info) {
          if (info.needUpdate && mounted) {
            showDialog(
                context: navigator.context,
                builder: (context) => UpdaterDialog(info: info));
          }
        });
      }
    });
  }

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
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    navigator.pushNamed(SettingScreen.route);
                  },
                ),
                IconButton(
                  tooltip: I18n.format("homepage.data.folder.open"),
                  icon: const Icon(Icons.folder),
                  onPressed: () {
                    Uttily.openFileManager(RPMPath.currentDataHome);
                  },
                ),
                IconButton(
                  tooltip: I18n.format("homepage.about"),
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PushTransitions(builder: (context) => AboutScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () => LauncherInfo.feedback(context),
                  tooltip: I18n.format("homepage.bug_report"),
                ),
                IconButton(
                  icon: const Icon(Icons.change_circle),
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
                                        const Icon(Icons.done_outlined,
                                            size: 30),
                                      ],
                                    ),
                                    actions: const [OkClose()],
                                  );
                                }
                              } else {
                                return AlertDialog(
                                  title: I18nText.tipsInfoText(),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      I18nText("updater.check.checking"),
                                      const SizedBox(
                                        width: 30.0,
                                        height: 30.0,
                                        child: FittedBox(child: RWLLoading()),
                                      ),
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
                icon: const Icon(Icons.sports_esports),
                text: I18n.format('homepage.tabs.instance')),
            Tab(
                icon: const NewFeaturesWidget(child: Icon(LineIcons.server)),
                text: I18n.format('homepage.tabs.server')),
            Tab(
                icon: const Icon(Icons.notifications),
                text: I18n.format('homepage.tabs.news')),
          ]),
          actions: const [
            AccountManageButton(),
          ],
        ),
        body: TabBarView(
          children: [
            const InstanceView(side: MinecraftSide.client),
            const InstanceView(side: MinecraftSide.server),
            FutureBuilder(
              future: RPMHttpClient().get(minecraftNewsRSS),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  Response response = snapshot.data;
                  XmlDocument xmlDocument = XmlDocument.parse(response.data);
                  MinecraftNews news = MinecraftNews.fromXml(xmlDocument);
                  return MinecraftNewsView(news: news);
                } else {
                  return const RWLLoading();
                }
              },
            ),
          ],
        ),
        floatingActionButton: const _FloatingAction(),
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

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
                  builder: (context) => const VersionSelection(
                        side: MinecraftSide.client,
                      )));
        },
        tooltip: I18n.format("version.list.instance.add"),
        child: const Icon(Icons.add),
      );
    } else if (index == 1) {
      return FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
              context,
              PushTransitions(
                  builder: (context) => const VersionSelection(
                        side: MinecraftSide.server,
                      )));
        },
        tooltip: I18n.format("version.list.instance.add.server"),
        child: const Icon(Icons.add),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

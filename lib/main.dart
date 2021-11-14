import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Route/GenerateRoute.dart';
import 'package:rpmlauncher/Route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';

import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/LinkText.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:xml/xml.dart';

import 'Utility/Datas.dart';
import 'Utility/LauncherInfo.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';
import 'Utility/Config.dart';
import 'Function/Counter.dart';
import 'Utility/Intents.dart';
import 'Utility/Loggger.dart';
import 'Utility/Theme.dart';
import 'Utility/I18n.dart';
import 'Utility/Utility.dart';
import 'View/InstanceView.dart';
import 'Widget/RWLLoading.dart';
import 'Utility/RPMPath.dart';

final Logger logger = Logger.currentLogger;
List<String> launcherArgs = [];
Directory get dataHome {
  try {
    return navigator.context.read<Counter>().dataHome;
  } catch (e) {
    return RPMPath.currentDataHome;
  }
}

final NavigatorState navigator = NavigationService.navigationKey.currentState!;

class PushTransitions<T> extends MaterialPageRoute<T> {
  PushTransitions({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

void main(List<String>? _args) async {
  launcherArgs = _args ?? [];
  run();
}

Future<void> run() async {
  runZonedGuarded(() async {
    LauncherInfo.startTime = DateTime.now();
    LauncherInfo.isDebugMode = kDebugMode;
    WidgetsFlutterBinding.ensureInitialized();
    await Datas.init();
    logger.info("Starting");

    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FlutterError.presentError(errorDetails);
      logger.error(ErrorType.flutter, errorDetails.exceptionAsString(),
          stackTrace: errorDetails.stack ?? StackTrace.current);
    };

    SentryFlutter.init((options) {
      options.release = "rpmlauncher@${LauncherInfo.getFullVersion()}";
      options.dsn =
          'https://18a8e66bd35c444abc0a8fa5b55843d7@o1068024.ingest.sentry.io/6062176';
      options.tracesSampleRate = 1.0;

      FutureOr<SentryEvent?> beforeSend(SentryEvent event,
          {dynamic hint}) async {
        if (Config.getValue('init') == true) {
          return event;
        } else {
          return null;
        }
      }

      options.beforeSend = beforeSend;
      if (LauncherInfo.isDebugMode) {
        options.reportSilentFlutterErrors = true;
      }

      Sentry.configureScope(
        (scope) => scope.user = SentryUser(
            id: Config.getValue('ga_client_id'),
            username: Account.getDefault()?.username),
      );
    },
        appRunner: () => runApp(
              Provider(
                  create: (context) {
                    logger.info("Provider Create");
                    return Counter();
                  },
                  child: LauncherHome()),
            ));

    logger.info("OS Version: ${await RPMLauncherPlugin.platformVersion}");

    if (LauncherInfo.autoFullScreen) {
      DesktopWindow.setFullScreen(true);
    }

    await googleAnalytics.ping();

    if (Config.getValue('discord_rpc')) {
      discordRPC.handler.start(autoRegister: true);
      discordRPC.handler.updatePresence(
        DiscordPresence(
            state: 'https://www.rpmtw.ga/RWL',
            details: '正在使用 RPMLauncher 來遊玩 Minecraft',
            startTimeStamp: LauncherInfo.startTime.millisecondsSinceEpoch,
            largeImageKey: 'rwl_logo',
            largeImageText: 'RPMLauncher 是一個多功能的 Minecraft 啟動器。',
            smallImageKey: 'minecraft',
            smallImageText:
                '啟動器版本: ${LauncherInfo.getFullVersion()} - ${LauncherInfo.getVersionType().name}'),
      );
    }

    logger.info("Start Done");
  }, (error, stackTrace) {
    logger.error(ErrorType.unknown, error, stackTrace: stackTrace);
  });
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          tooltipTheme: TooltipThemeData(
            waitDuration: Duration(milliseconds: 200),
          ),
          textTheme: TextTheme(
            bodyText1: TextStyle(
                fontFamily: 'font',
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.toInt(Themes.dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          tooltipTheme: TooltipThemeData(
            waitDuration: Duration(milliseconds: 200),
          ),
          textTheme: TextTheme(
              bodyText1: TextStyle(
            fontFamily: 'font',
            fontFeatures: [FontFeature.tabularFigures()],
          ))),
    });
    return DynamicTheme(
        themeCollection: themeCollection,
        defaultThemeId: ThemeUtility.toInt(Themes.dark),
        builder: (context, theme) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: NavigationService.navigationKey,
              title: LauncherInfo.getUpperCaseName(),
              theme: theme,
              navigatorObservers: [
                RPMNavigatorObserver(),
                SentryNavigatorObserver()
              ],
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.escape): EscIntent(),
                LogicalKeySet(
                        LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
                    RestartIntent(),
              },
              actions: <Type, Action<Intent>>{
                EscIntent:
                    CallbackAction<EscIntent>(onInvoke: (EscIntent intent) {
                  if (navigator.canPop()) {
                    navigator.pop(true);
                  }
                }),
                RestartIntent: CallbackAction<RestartIntent>(
                    onInvoke: (RestartIntent intent) {
                  logger.send("Reload");
                  navigator.pushReplacementNamed(HomePage.route);
                  Future.delayed(Duration(seconds: 2), () {
                    showDialog(
                        context: navigator.context,
                        builder: (context) => AlertDialog(
                              title: Text(I18n.format('uttily.reload')),
                              actions: [OkClose()],
                            ));
                  });
                }),
              },
              builder: (BuildContext context, Widget? widget) {
                String _ = 'RPMLauncher 崩潰啦！\n發生未知錯誤，造成您的不便，我們深感抱歉。';
                TextStyle _style = TextStyle(fontSize: 30);

                if (!kTestMode) {
                  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                    return Material(
                        child: Column(
                      children: [
                        Text(_, style: _style, textAlign: TextAlign.center),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "錯誤訊息",
                              style: _style,
                            ),
                            IconButton(
                              icon: Icon(Icons.copy_outlined),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: errorDetails.exceptionAsString()));
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(errorDetails.exceptionAsString()),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "堆棧跟踪 (StackTrace)",
                              style: _style,
                            ),
                            IconButton(
                              icon: Icon(Icons.copy_outlined),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: errorDetails.stack.toString()));
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: errorDetails.stack
                                .toString()
                                .split('\n')
                                .map((e) => Text(e))
                                .toList(),
                          ),
                        ),
                      ],
                    ));
                  };
                }

                return widget ??
                    Scaffold(body: Center(child: Text(_, style: _style)));
              },
              onGenerateInitialRoutes: (String initialRouteName) {
                return [
                  navigator.widget.onGenerateRoute!(RPMRouteSettings(
                      name: LauncherInfo.route,
                      newWindow: LauncherInfo.newWindow)) as Route,
                ];
              },
              onGenerateRoute: (RouteSettings settings) =>
                  onGenerateRoute(settings));
        });
  }
}

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  late String name;
  bool start = true;

  @override
  Widget build(BuildContext context) {
    if (!isInit) {
      if (Config.getValue('init') == false) {
        Future.delayed(Duration.zero, () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  StatefulBuilder(builder: (context, setState) {
                    return AlertDialog(
                        title: Text(I18n.format('init.quick_setup.title'),
                            textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "${I18n.format('init.quick_setup.content')}\n"),
                            SelectorLanguageWidget(setWidgetState: setState),
                          ],
                        ),
                        actions: [
                          OkClose(
                            title: "下一步",
                            onOk: () {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                          scrollable: true,
                                          title: Text("RPMLauncher 資料收集政策",
                                              textAlign: TextAlign.center),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  "為了優化 RPMLauncher 使用者體驗，本軟體將會蒐集以下資訊"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  "- 作業系統/版本\n- 本軟體版本資訊\n- 本軟體發生錯誤時的資料\n- IP (已混淆)\n- 頁面瀏覽資訊"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  "本軟體使用的資料收集服務為 Google Analytics 與 SENTRY ，使用本軟體也代表您同意這些服務的隱私條款。"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              LinkText(
                                                  link:
                                                      "https://policies.google.com/privacy",
                                                  text: "Google 隱私權與條款"),
                                              LinkText(
                                                  link:
                                                      "https://sentry.io/privacy/",
                                                  text: "SENTRY 隱私權政策")
                                            ],
                                          ),
                                          actions: [
                                            OkClose(
                                              title: "我不同意",
                                              color: Colors.white24,
                                              onOk: () {
                                                exit(0);
                                              },
                                            ),
                                            OkClose(
                                              title: "我同意",
                                              onOk: () {
                                                Config.change('init', true);
                                                googleAnalytics.firstVisit();
                                              },
                                            ),
                                          ]));
                            },
                          ),
                        ]);
                  }));
        });
      } else {
        VersionTypes updateChannel =
            Updater.getVersionTypeFromString(Config.getValue('update_channel'));

        Updater.checkForUpdate(updateChannel).then((VersionInfo info) {
          if (info.needUpdate == true) {
            Future.delayed(Duration.zero, () {
              TextStyle _title = TextStyle(fontSize: 20);
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                            title: Text("更新 RPMLauncher",
                                textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                I18nText(
                                  'updater.tips',
                                  style: TextStyle(fontSize: 18),
                                ),
                                Divider(),
                                I18nText(
                                  "updater.latest",
                                  args: {
                                    "version": info.version,
                                    "buildID": info.buildID
                                  },
                                  style: _title,
                                ),
                                Divider(),
                                I18nText(
                                  "updater.current",
                                  args: {
                                    "version": LauncherInfo.getVersion(),
                                    "buildID": LauncherInfo.getBuildID()
                                  },
                                  style: _title,
                                ),
                                Divider(),
                                I18nText(
                                  "updater.changelog",
                                  style: _title,
                                ),
                                Divider(),
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height:
                                        MediaQuery.of(context).size.height / 3,
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
                                                title: Text(I18n.format(
                                                    'gui.tips.info')),
                                                content: Text(
                                                    "RPMLauncher 目前不支援 MacOS 自動更新，抱歉造成困擾。"),
                                                actions: [OkClose()],
                                              ));
                                    } else {
                                      if (Platform.isLinux &&
                                          LauncherInfo.isSnapcraftApp) {
                                        xdgOpen("snap://rpmlauncher?channel=latest/" +
                                            (Updater.getVersionTypeFromString(
                                                        Config.getValue(
                                                            'update_channel')) ==
                                                    VersionTypes.stable
                                                ? "stable"
                                                : "beta"));
                                      } else {
                                        Updater.download(info);
                                      }
                                    }
                                  },
                                  child: I18nText("updater.tips.yes"))
                            ]);
                      }));
            });
          }
        });
      }

      isInit = true;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 300,
          leading: Row(
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
                waitDuration: Duration(milliseconds: 300),
                child: IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    navigator.pushNamed(SettingScreen.route);
                  },
                ),
              ),
              Tooltip(
                message: I18n.format("homepage.data.folder.open"),
                waitDuration: Duration(milliseconds: 300),
                child: IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    Uttily.openFileManager(RPMPath.currentDataHome);
                  },
                ),
              ),
              Tooltip(
                message: I18n.format("homepage.about"),
                waitDuration: Duration(milliseconds: 300),
                child: IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PushTransitions(builder: (context) => AboutScreen()),
                    );
                  },
                ),
              )
            ],
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
              future: Dio().get(minecraftNewsRSS),
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
            Uttily.javaCheck(hasJava: () {
              Navigator.push(context,
                  PushTransitions(builder: (context) => VersionSelection()));
            });
          },
          tooltip: I18n.format("version.list.instance.add"),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

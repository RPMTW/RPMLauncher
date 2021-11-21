import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:dio/dio.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/Dialog/UpdaterDialog.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:system_info/system_info.dart';
import 'package:xml/xml.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Route/GenerateRoute.dart';
import 'package:rpmlauncher/Route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/LinkText.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';

import 'Function/Counter.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';
import 'Utility/Config.dart';
import 'Utility/Data.dart';
import 'Utility/I18n.dart';
import 'Utility/Intents.dart';
import 'Utility/LauncherInfo.dart';
import 'Utility/Logger.dart';
import 'Utility/RPMPath.dart';
import 'Utility/Theme.dart';
import 'Utility/Utility.dart';
import 'View/InstanceView.dart';
import 'Widget/RWLLoading.dart';

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

Future<void> main(List<String>? _args) async {
  launcherArgs = _args ?? [];
  await run();
}

Future<void> run() async {
  await runZonedGuarded(() async {
    LauncherInfo.startTime = DateTime.now();
    LauncherInfo.isDebugMode = kDebugMode;
    WidgetsFlutterBinding.ensureInitialized();
    await Data.init();
    logger.info("Starting");

    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FlutterError.presentError(errorDetails);
      logger.error(ErrorType.flutter, errorDetails.exceptionAsString(),
          stackTrace: errorDetails.stack ?? StackTrace.current);
    };

    await SentryFlutter.init(
      (options) {
        options.release = "rpmlauncher@${LauncherInfo.getFullVersion()}";
        options.dsn =
            'https://18a8e66bd35c444abc0a8fa5b55843d7@o1068024.ingest.sentry.io/6062176';
        options.tracesSampleRate = 1.0;
        FutureOr<SentryEvent?> beforeSend(SentryEvent event,
            {dynamic hint}) async {
          if (Config.getValue('init') == true) {
            Size _size =
                MediaQueryData.fromWindow(WidgetsBinding.instance!.window).size;
            String? userName = Account.getDefault()?.username ??
                Platform.environment['USERNAME'];

            SentryEvent _newEvent;

            _newEvent = event.copyWith(
                user: SentryUser(
                    id: Config.getValue('ga_client_id'),
                    username: userName,
                    email: "$userName@rpmtw.ga",
                    extras: {
                      "userOrigin": LauncherInfo.userOrigin,
                    }),
                level: SentryLevel.error,
                contexts: event.contexts.copyWith(
                    device: SentryDevice(
                  arch: SysInfo.kernelArchitecture,
                  memorySize: await Uttily.getTotalPhysicalMemory(),
                  language: Platform.localeName,
                  name: Platform.localHostname,
                  screenHeightPixels: _size.height.toInt(),
                  screenWidthPixels: _size.width.toInt(),
                  screenResolution: "${_size.width}x${_size.height}",
                  theme:
                      ThemeUtility.getThemeEnumByID(Config.getValue('theme_id'))
                          .name,
                  timezone: DateTime.now().timeZoneName,
                )));

            return _newEvent;
          } else {
            return null;
          }
        }

        options.beforeSend = beforeSend;
        if (LauncherInfo.isDebugMode) {
          options.reportSilentFlutterErrors = true;
        }
      },
    );

    runApp(
      Provider(
          create: (context) {
            logger.info("Provider Create");
            return Counter();
          },
          child: LauncherHome()),
    );

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
            details: I18n.format('rpmlauncher.discord_rpc.details'),
            startTimeStamp: LauncherInfo.startTime.millisecondsSinceEpoch,
            largeImageKey: 'rwl_logo',
            largeImageText:
                I18n.format('rpmlauncher.discord_rpc.largeImageText'),
            smallImageKey: 'minecraft',
            smallImageText:
                '${LauncherInfo.getFullVersion()} - ${LauncherInfo.getVersionType().name}'),
      );
    }

    logger.info("Start Done");
  }, (exception, stackTrace) async {
    logger.error(ErrorType.unknown, exception, stackTrace: stackTrace);
    if (!LauncherInfo.isDebugMode && !kTestMode) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
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
                String _ = I18n.format('rpmlauncher.crash');
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
                            I18nText(
                              "gui.error.message",
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
                            I18nText(
                              "rpmlauncher.crash.stacktrace",
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
                            title: I18n.format('gui.next'),
                            onOk: () {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                          scrollable: true,
                                          title: I18nText(
                                              "rpmlauncher.privacy.title",
                                              textAlign: TextAlign.center),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              I18nText(
                                                  "rpmlauncher.privacy.content.1"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              I18nText(
                                                  "rpmlauncher.privacy.content.2"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              I18nText(
                                                  "rpmlauncher.privacy.content.3"),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              LinkText(
                                                  link:
                                                      "https://policies.google.com/privacy",
                                                  text: I18n.format(
                                                      'rpmlauncher.privacy.google')),
                                              LinkText(
                                                  link:
                                                      "https://sentry.io/privacy/",
                                                  text: I18n.format(
                                                      'rpmlauncher.privacy.sentry'))
                                            ],
                                          ),
                                          actions: [
                                            OkClose(
                                              title:
                                                  I18n.format('gui.disagree'),
                                              color: Colors.white24,
                                              onOk: () {
                                                exit(0);
                                              },
                                            ),
                                            OkClose(
                                              title: I18n.format('gui.agree'),
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
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => UpdaterDialog(info: info));
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

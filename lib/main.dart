import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:args/args.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:dio_http/dio_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/MinecraftNews.dart';
import 'package:rpmlauncher/Route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/Log.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/View/MinecraftNewsView.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:split_view/split_view.dart';
import 'package:xml/xml.dart';

import 'Launcher/GameRepository.dart';
import 'Launcher/InstanceRepository.dart';
import 'Utility/Datas.dart';
import 'Utility/LauncherInfo.dart';
import 'Model/Instance.dart';
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
import 'Widget/RWLLoading.dart';
import 'Utility/RPMPath.dart';

late final Analytics ga;
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

void main(List<String> _args) async {
  LauncherInfo.startTime = DateTime.now();
  LauncherInfo.isDebugMode = kDebugMode;
  DiscordRPC.initialize();
  Datas.init();
  await RPMPath.init();
  launcherArgs = _args;
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.init();
  run().catchError((e, stackTrace) {
    logger.error(ErrorType.unknown, e, stackTrace: stackTrace);
  });
}

Future<void> run() async {
  runZonedGuarded(() async {
    logger.info("Starting");
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      logger.error(ErrorType.flutter, errorDetails.exceptionAsString(),
          stackTrace: errorDetails.stack ?? StackTrace.current);

      // showDialog(
      //     context: navigator.context,
      //     builder: (context) => AlertDialog(
      //           title: Text("RPMLauncher 崩潰啦"),
      //           content: Text(errorDetails.toString()),
      //         ));
    };

    runApp(Provider(
        create: (context) async {
          logger.info("Provider Create");
          return Counter();
        },
        child: LauncherHome()));

    logger.info("OS Version: ${await RPMLauncherPlugin.platformVersion}");

    if (LauncherInfo.autoFullScreen) {
      DesktopWindow.setFullScreen(true);
    }

    ga = Analytics();
    await ga.ping();

    discordRPC.start(autoRegister: true);

    discordRPC.updatePresence(
      DiscordPresence(
          state: 'https://www.rpmtw.ga/RWL',
          details: '正在使用 RPMLauncher 來遊玩 Minecraft',
          startTimeStamp: LauncherInfo.startTime.millisecondsSinceEpoch,
          largeImageKey: 'rwl_logo',
          largeImageText: 'RPMLauncher 是一個多功能的 Minecraft 啟動器。',
          smallImageKey: 'minecraft',
          smallImageText: '啟動器版本: ${LauncherInfo.getFullVersion()}'),
    );
  }, (error, stackTrace) {
    logger.error(ErrorType.unknown, error, stackTrace: stackTrace);
  });
  logger.info("Start Done");
}

RPMRouteSettings getInitRouteSettings() {
  String _route = '/';
  bool _newWindow = false;
  ArgParser parser = ArgParser();
  parser.addOption('route', defaultsTo: '/', callback: (route) {
    _route = route!;
  });

  parser.addOption('newWindow', defaultsTo: 'false', callback: (newWindow) {
    _newWindow = newWindow!.toBool();
  });

  try {
    parser.parse(launcherArgs);
  } catch (e) {}

  return RPMRouteSettings(name: _route, newWindow: _newWindow);
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          textTheme: TextTheme(
            bodyText1: TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.toInt(Themes.dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          textTheme: TextTheme(
              bodyText1: TextStyle(
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
              navigatorObservers: [RPMNavigatorObserver()],
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
              onGenerateInitialRoutes: (String initialRouteName) {
                RPMRouteSettings routeSettings = getInitRouteSettings();
                return [
                  navigator.widget.onGenerateRoute!(routeSettings) as Route,
                ];
              },
              onGenerateRoute: (RouteSettings settings) {
                RPMRouteSettings _settings =
                    RPMRouteSettings.fromRouteSettings(settings);
                if (_settings.name == HomePage.route) {
                  _settings.routeName = "home_page";

                  return PushTransitions(
                      settings: _settings,
                      builder: (context) => FutureBuilder(
                          future: Future.delayed(Duration(seconds: 2)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              Connectivity()
                                  .checkConnectivity()
                                  .then((value) async {
                                if (value == ConnectivityResult.none &&
                                    (await Dio().get('https://www.google.com'))
                                            .statusCode !=
                                        200) {
                                  WidgetsBinding.instance!
                                      .addPostFrameCallback((timeStamp) {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: I18nText('gui.error.info'),
                                              content: I18nText(
                                                  "homepage.nonetwork"),
                                              actions: [
                                                OkClose(
                                                  onOk: () {
                                                    exit(0);
                                                  },
                                                )
                                              ],
                                            ));
                                  });
                                }
                              });

                              return HomePage();
                            } else {
                              return Material(
                                child: RWLLoading(animations: true, logo: true),
                              );
                            }
                          }));
                }

                Uri uri = Uri.parse(_settings.name!);
                if (_settings.name!.startsWith('/instance/') &&
                    uri.pathSegments.length > 2) {
                  // "/instance/${InstanceDirName}"
                  String instanceDirName = uri.pathSegments[1];

                  if (_settings.name!
                      .startsWith('/instance/$instanceDirName/edit')) {
                    _settings.routeName = "edit_instance";
                    return PushTransitions(
                        settings: _settings,
                        builder: (context) => EditInstance(
                            instanceDirName: instanceDirName,
                            newWindow: _settings.newWindow));
                  } else if (_settings.name!
                      .startsWith('/instance/$instanceDirName/launcher')) {
                    _settings.routeName = "launcher_instance";
                    return PushTransitions(
                        settings: _settings,
                        builder: (context) => LogScreen(
                            instanceDirName: instanceDirName,
                            newWindow: _settings.newWindow));
                  }
                }

                if (_settings.name == SettingScreen.route) {
                  _settings.routeName = "settings";
                  return PushTransitions(
                      settings: _settings,
                      builder: (context) => SettingScreen());
                } else if (_settings.name == AccountScreen.route) {
                  _settings.routeName = "account";
                  return PushTransitions(
                      settings: _settings,
                      builder: (context) => AccountScreen());
                }

                return PushTransitions(
                    settings: _settings, builder: (context) => HomePage());
              });
        });
  }
}

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Directory instanceRootDir = GameRepository.getInstanceRootDir();

  Future<List<Instance>> getInstanceList() async {
    List<Instance> instances = [];

    await instanceRootDir.list().forEach((fse) {
      if (fse is Directory &&
          fse
              .listSync()
              .any((file) => basename(file.path) == "instance.json")) {
        instances
            .add(Instance(InstanceRepository.getinstanceDirNameByDir(fse)));
      }
    });
    return instances;
  }

  @override
  void initState() {
    instanceRootDir.watch().listen((event) {
      try {
        setState(() {});
      } catch (e) {}
    });
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      run();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  late String name;
  bool start = true;
  int chooseIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (!isInit) {
      if (Config.getValue('init') == false) {
        ga.firstVisit();
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
                            onOk: () {
                              Config.change('init', true);
                            },
                          )
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
                                I18nText(
                                  "updater.latest",
                                  args: {
                                    "version": info.version,
                                    "versionCode": info.versionCode
                                  },
                                  style: _title,
                                ),
                                I18nText(
                                  "updater.current",
                                  args: {
                                    "version": LauncherInfo.getVersion(),
                                    "versionCode": LauncherInfo.getVersionCode()
                                  },
                                  style: _title,
                                ),
                                I18nText(
                                  "updater.changelog",
                                  style: _title,
                                ),
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    child: Markdown(
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet(
                                          textAlign: WrapAlignment.center,
                                          textScaleFactor: 1.5,
                                          h1Align: WrapAlignment.center,
                                          unorderedListAlign:
                                              WrapAlignment.center),
                                      data: info.changelog.toString(),
                                      onTapLink: (text, url, title) {
                                        if (url != null) {
                                          Uttily.openUrl(url);
                                        }
                                      },
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
              IconButton(
                  onPressed: () async {
                    await Uttily.openUrl(LauncherInfo.homePageUrl);
                  },
                  icon: Image.asset("images/Logo.png", scale: 4),
                  tooltip: I18n.format("homepage.website")),
              IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    navigator.pushNamed(SettingScreen.route);
                  },
                  tooltip: I18n.format("gui.settings")),
              IconButton(
                icon: Icon(Icons.folder),
                onPressed: () {
                  Uttily.openFileManager(RPMPath.currentDataHome);
                },
                tooltip: I18n.format("homepage.data.folder.open"),
              ),
              IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PushTransitions(builder: (context) => AboutScreen()),
                    );
                  },
                  tooltip: I18n.format("homepage.about"))
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
            FutureBuilder(
              builder: (context, AsyncSnapshot<List<Instance>> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isNotEmpty) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: SplitView(
                          gripSize: 0,
                          controller: SplitViewController(weights: [0.7]),
                          children: [
                            Builder(
                              builder: (context) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  itemCount: snapshot.data!.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 8),
                                  physics: ScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    try {
                                      Instance instance = snapshot.data![index];

                                      late Widget photo;
                                      if (File(join(instance.path, "icon.png"))
                                          .existsSync()) {
                                        try {
                                          photo = Image.file(File(
                                              join(instance.path, "icon.png")));
                                        } catch (err) {
                                          photo = Icon(
                                            Icons.image,
                                          );
                                        }
                                      } else {
                                        photo = Icon(
                                          Icons.image,
                                        );
                                      }

                                      return ContextMenuArea(
                                        items: [
                                          ListTile(
                                            title:
                                                I18nText("gui.instance.launch"),
                                            subtitle: I18nText(
                                                "gui.instance.launch.subtitle"),
                                            onTap: () {
                                              navigator.pop();
                                              instance.launcher();
                                            },
                                          ),
                                          ListTile(
                                            title: I18nText("gui.edit"),
                                            subtitle:
                                                I18nText("gui.edit.subtitle"),
                                            onTap: () {
                                              navigator.pop();
                                              instance.edit();
                                            },
                                          ),
                                          ListTile(
                                            title: Text("資料夾"),
                                            subtitle: Text("開啟安裝檔的資料夾位置"),
                                            onTap: () {
                                              navigator.pop();
                                              instance.openFolder();
                                            },
                                          ),
                                          ListTile(
                                            title: I18nText("gui.copy"),
                                            subtitle: Text("複製此安裝檔"),
                                            onTap: () {
                                              navigator.pop();
                                              instance.copy();
                                            },
                                          ),
                                          ListTile(
                                            title: I18nText('gui.delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                            subtitle: Text("刪除此安裝檔"),
                                            onTap: () {
                                              navigator.pop();
                                              instance.delete();
                                            },
                                          )
                                        ],
                                        child: Card(
                                          child: InkWell(
                                            onTap: () {
                                              chooseIndex = index;
                                              setState(() {});
                                            },
                                            child: Column(
                                              children: [
                                                Expanded(child: photo),
                                                Text(instance.name,
                                                    textAlign:
                                                        TextAlign.center),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    } on FileSystemException {
                                      return SizedBox.shrink();
                                    } catch (e, stackTrace) {
                                      logger.error(ErrorType.unknown, e,
                                          stackTrace: stackTrace);
                                      return SizedBox.shrink();
                                    }
                                  },
                                );
                              },
                            ),
                            Builder(builder: (context) {
                              if (chooseIndex == -1 ||
                                  (snapshot.data!.length - 1) < chooseIndex ||
                                  !InstanceRepository.instanceConfigFile(
                                          snapshot.data![chooseIndex].path)
                                      .existsSync()) {
                                return Container();
                              } else {
                                Instance instance = snapshot.data![chooseIndex];

                                return Builder(
                                  builder: (context) {
                                    late Widget photo;

                                    if (FileSystemEntity.typeSync(
                                            join(instance.path, "icon.png")) !=
                                        FileSystemEntityType.notFound) {
                                      photo = Image.file(File(
                                          join(instance.path, "icon.png")));
                                    } else {
                                      photo = const Icon(
                                        Icons.image,
                                        size: 100,
                                      );
                                    }

                                    return Column(
                                      children: [
                                        SizedBox(
                                          child: photo,
                                          width: 200,
                                          height: 160,
                                        ),
                                        Text(instance.name,
                                            textAlign: TextAlign.center),
                                        SizedBox(height: 12),
                                        TextButton(
                                            onPressed: () {
                                              instance.launcher();
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.play_arrow,
                                                ),
                                                SizedBox(width: 5),
                                                Text(I18n.format(
                                                    "gui.instance.launch")),
                                              ],
                                            )),
                                        SizedBox(height: 12),
                                        TextButton(
                                            onPressed: () {
                                              instance.edit();
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                ),
                                                SizedBox(width: 5),
                                                Text(I18n.format("gui.edit")),
                                              ],
                                            )),
                                        SizedBox(height: 12),
                                        TextButton(
                                            onPressed: () {
                                              instance.copy();
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.content_copy,
                                                ),
                                                SizedBox(width: 5),
                                                Text(I18n.format("gui.copy")),
                                              ],
                                            )),
                                        SizedBox(height: 12),
                                        TextButton(
                                            onPressed: () {
                                              instance.delete();
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                ),
                                                SizedBox(width: 5),
                                                Text(I18n.format("gui.delete")),
                                              ],
                                            )),
                                      ],
                                    );
                                  },
                                );
                              }
                            }),
                          ],
                          viewMode: SplitViewMode.Horizontal),
                    );
                  } else {
                    return Transform.scale(
                        child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                              Icon(
                                Icons.today,
                              ),
                              Text(I18n.format("homepage.instance.found")),
                              Text(I18n.format("homepage.instance.found.tips"))
                            ])),
                        scale: 2);
                  }
                } else {
                  return RWLLoading(
                    animations: false,
                    logo: true,
                  );
                }
              },
              future: getInstanceList(),
            ),
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

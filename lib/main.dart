import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:args/args.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/Route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/Log.dart';
import 'package:rpmlauncher/Function/Analytics.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:split_view/split_view.dart';

import 'Launcher/GameRepository.dart';
import 'Launcher/InstanceRepository.dart';
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
import 'Utility/i18n.dart';
import 'Utility/utility.dart';
import 'Widget/RWLLoading.dart';
import 'path.dart';

bool isInit = false;
late final Analytics ga;
final Logger logger = Logger.currentLogger;
List<String> launcherArgs = [];
Directory get dataHome {
  try {
    return navigator.context.read<Counter>().dataHome;
  } catch (e) {
    return path.currentDataHome;
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
  LauncherInfo.isDebugMode = kDebugMode;
  await path.init();
  launcherArgs = _args;
  WidgetsFlutterBinding.ensureInitialized();
  await i18n.init();
  run().catchError((e) {
    logger.error(ErrorType.unknown, e);
  });
}

Future<void> run() async {
  runZonedGuarded(() async {
    logger.info("Starting");

    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      logger.error(ErrorType.flutter,
          "${errorDetails.exceptionAsString()}\n${errorDetails.stack}");

      // showDialog(
      //     context: navigator.context,
      //     builder: (context) => AlertDialog(
      //           title: Text("RPMLauncher 崩潰啦"),
      //           content: Text(errorDetails.toString()),
      //         ));
    };
    runApp(Provider(
        create: (context) {
          logger.info("Provider Create");
          return Counter();
        },
        child: LauncherHome()));

    if (LauncherInfo.autoFullScreen) {
      await DesktopWindow.setFullScreen(true);
    }

    ga = Analytics();
    await ga.ping();

    logger.info("OS Version: ${await RPMLauncherPlugin.platformVersion}");
  }, (error, stackTrace) {
    logger.error(ErrorType.unknown, "$error\n$stackTrace");
  });
  logger.info("Start Done");
}

RouteSettings getInitRouteSettings() {
  String _route = '/';
  Map _arguments = {};
  ArgParser parser = ArgParser();
  parser.addOption('route', defaultsTo: '/', callback: (route) {
    _route = route!;
  });
  parser.addOption('arguments', defaultsTo: '{}', callback: (arguments) {
    _arguments = json.decode(arguments!);
  });

  parser.parse(launcherArgs);
  return RouteSettings(name: _route, arguments: _arguments);
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.Light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          textTheme: TextTheme(
            bodyText1: TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.toInt(Themes.Dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          textTheme: TextTheme(
              bodyText1: TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ))),
    });
    return DynamicTheme(
        themeCollection: themeCollection,
        defaultThemeId: ThemeUtility.toInt(Themes.Dark),
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
                              title: Text(i18n.format('uttily.reload')),
                              actions: [OkClose()],
                            ));
                  });
                }),
              },
              onGenerateInitialRoutes: (String initialRouteName) {
                return [
                  navigator.widget.onGenerateRoute!(RouteSettings(
                      name: getInitRouteSettings().name,
                      arguments: getInitRouteSettings().arguments)) as Route,
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
                              Connectivity().checkConnectivity().then((value) {
                                if (value == ConnectivityResult.none) {
                                  WidgetsBinding.instance!
                                      .addPostFrameCallback((timeStamp) {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              title: i18nText('gui.error.info'),
                                              content: Text(
                                                  "RPMLauncher 無法在無網路環境下執行，抱歉造成您的困擾。"),
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
                            NewWindow:
                                (_settings.arguments as Map)['NewWindow']));
                  } else if (_settings.name!
                      .startsWith('/instance/$instanceDirName/launcher')) {
                    _settings.routeName = "launcher_instance";
                    return PushTransitions(
                        settings: _settings,
                        builder: (context) => LogScreen(
                            instanceDirName: instanceDirName,
                            newWindow:
                                (_settings.arguments as Map)['NewWindow']));
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
                        title: Text(i18n.format('init.quick_setup.title'),
                            textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "${i18n.format('init.quick_setup.content')}\n"),
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
                                i18nText(
                                  'updater.tips',
                                  style: TextStyle(fontSize: 18),
                                ),
                                i18nText(
                                  "updater.latest",
                                  args: {
                                    "version": info.version,
                                    "versionCode": info.versionCode
                                  },
                                  style: _title,
                                ),
                                i18nText(
                                  "updater.current",
                                  args: {
                                    "version": LauncherInfo.getVersion(),
                                    "versionCode": LauncherInfo.getVersionCode()
                                  },
                                  style: _title,
                                ),
                                i18nText(
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
                                          utility.openUrl(url);
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
                                  child: i18nText("updater.tips.not")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (Platform.isMacOS) {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                                title: Text(i18n
                                                    .format('gui.tips.info')),
                                                content: Text(
                                                    "RPMLauncher 目前不支援 MacOS 自動更新，抱歉造成困擾。"),
                                                actions: [OkClose()],
                                              ));
                                    } else {
                                      Updater.download(info);
                                    }
                                  },
                                  child: i18nText("updater.tips.yes"))
                            ]);
                      }));
            });
          }
        });
      }

      isInit = true;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 300,
        leading: Row(
          children: [
            IconButton(
                onPressed: () async {
                  await utility.openUrl(LauncherInfo.homePageUrl);
                },
                icon: Image.asset("images/Logo.png", scale: 4),
                tooltip: i18n.format("homepage.website")),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  navigator.pushNamed(SettingScreen.route);
                },
                tooltip: i18n.format("gui.settings")),
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                utility.OpenFileManager(path.currentDataHome);
              },
              tooltip: i18n.format("homepage.data.folder.open"),
            ),
            IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  Navigator.push(
                    context,
                    PushTransitions(builder: (context) => AboutScreen()),
                  );
                },
                tooltip: i18n.format("homepage.about"))
          ],
        ),
        title: Text(
          LauncherInfo.getUpperCaseName(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              navigator.pushNamed(AccountScreen.route);
            },
            tooltip: i18n.format("account.title"),
          ),
        ],
      ),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<List<Instance>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              return SplitView(
                  gripSize: 0,
                  controller: SplitViewController(weights: [0.7]),
                  children: [
                    Builder(
                      builder: (context) {
                        return GridView.builder(
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
                                  photo = Image.file(
                                      File(join(instance.path, "icon.png")));
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
                                    title: i18nText("gui.instance.launch"),
                                    subtitle: Text("啟動遊戲"),
                                    onTap: () {
                                      navigator.pop();
                                      instance.launcher();
                                    },
                                  ),
                                  ListTile(
                                    title: i18nText("gui.edit"),
                                    subtitle: Text("調整模組、地圖、世界、資源包、光影等設定"),
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
                                    title: i18nText("gui.copy"),
                                    subtitle: Text("複製此安裝檔"),
                                    onTap: () {
                                      navigator.pop();
                                      instance.copy();
                                    },
                                  ),
                                  ListTile(
                                    title: i18nText('gui.delete',
                                        style: TextStyle(color: Colors.red)),
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
                                            textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } on FileSystemException {
                              return SizedBox.shrink();
                            } catch (e) {
                              logger.error(ErrorType.unknown, e);
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
                              photo = Image.file(
                                  File(join(instance.path, "icon.png")));
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
                                        Text(
                                            i18n.format("gui.instance.launch")),
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
                                        Text(i18n.format("gui.edit")),
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
                                        Text(i18n.format("gui.copy")),
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
                                        Text(i18n.format("gui.delete")),
                                      ],
                                    )),
                              ],
                            );
                          },
                        );
                      }
                    }),
                  ],
                  viewMode: SplitViewMode.Horizontal);
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
                        Text(i18n.format("homepage.instance.found")),
                        Text(i18n.format("homepage.instance.found.tips"))
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          utility.javaCheck(hasJava: () {
            Navigator.push(context,
                PushTransitions(builder: (context) => VersionSelection()));
          });
        },
        tooltip: i18n.format("version.list.instance.add"),
        child: Icon(Icons.add),
      ),
    );
  }
}

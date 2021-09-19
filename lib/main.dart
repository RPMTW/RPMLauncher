// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Screen/MojangAccount.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Launcher/GameRepository.dart';
import 'Launcher/InstanceRepository.dart';
import 'LauncherInfo.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/RefreshMSToken.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';
import 'Utility/Config.dart';
import 'Utility/Intents.dart';
import 'Utility/Loggger.dart';
import 'Utility/Theme.dart';
import 'Utility/i18n.dart';
import 'Utility/utility.dart';
import 'Widget/CheckAssets.dart';
import 'path.dart';

bool isInit = false;
late final Logger logger;
late final Directory dataHome;


final NavigatorState navigator = NavigationService.navigationKey.currentState!;

class PushTransitions<T> extends MaterialPageRoute<T> {
  PushTransitions({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return new FadeTransition(opacity: animation, child: child);
  }
}

void main() async {
  run().catchError((e) {
    logger.send(e);
  });
}

Future<void> run() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await path().init();
  await i18n.init();
  logger = Logger();
  logger.send("Starting");
  runApp(LauncherHome());
  logger.send("Start Done");
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.toInt(Themes.Light): ThemeData(
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          textTheme: new TextTheme(
            bodyText1: new TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.toInt(Themes.Dark): ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          textTheme: new TextTheme(
              bodyText1: new TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ))),
    });
    return Phoenix(
      child: DynamicTheme(
          themeCollection: themeCollection,
          defaultThemeId: ThemeUtility.toInt(Themes.Dark),
          builder: (context, theme) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: NavigationService.navigationKey,
              title: LauncherInfo.getUpperCaseName(),
              theme: theme,
              home: FutureBuilder(
                  future: Future.delayed(Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return HomePage();
                    } else {
                      return Material(
                        child: RWLLoading(Animations: true),
                      );
                    }
                  }),
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.escape): EscIntent(),
                LogicalKeySet(
                    LogicalKeyboardKey.control,
                    LogicalKeyboardKey.shift,
                    LogicalKeyboardKey.keyR): HotReloadIntent(),
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
                HotReloadIntent: CallbackAction<HotReloadIntent>(
                    onInvoke: (HotReloadIntent intent) {
                  logger.send("Hot Reload");
                  Phoenix.rebirth(navigator.context);
                  showDialog(
                      context: navigator.context,
                      builder: (context) => AlertDialog(
                            title: Text(i18n.format('uttily.reload.hot')),
                            actions: [OkClose()],
                          ));
                }),
                RestartIntent: CallbackAction<RestartIntent>(
                    onInvoke: (RestartIntent intent) {
                  logger.send("Reload");
                  runApp(LauncherHome());
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
            );
          }),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static Directory LauncherFolder = dataHome;
  Directory InstanceRootDir = GameRepository.getInstanceRootDir();

  Future<List<FileSystemEntity>> GetInstanceList() async {
    var list = await InstanceRootDir.list().where((FSE) {
      if (FSE is Directory) {
        return FSE
            .listSync()
            .any((file) => basename(file.path) == "instance.json");
      } else {
        return false;
      }
    }).toList();
    return list;
  }

  @override
  void initState() {
    InstanceRootDir.watch().listen((event) {
      setState(() {});
    });
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      main();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  String? choose;
  late String name;
  bool start = true;
  int chooseIndex = -1;

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
        VersionTypes UpdateChannel =
            Updater.getVersionTypeFromString(Config.getValue('update_channel'));

        Updater.checkForUpdate(UpdateChannel).then((VersionInfo info) {
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
                                SelectableText.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "偵測到您的 RPMLauncher 版本過舊，您是否需要更新，我們建議您更新以獲得更佳體驗\n",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        TextSpan(
                                          text:
                                              "最新版本: ${info.version}.${info.versionCode}\n",
                                          style: _title,
                                        ),
                                        TextSpan(
                                          text:
                                              "目前版本: ${LauncherInfo.getVersion()}.${LauncherInfo.getVersionCode()}\n",
                                          style: _title,
                                        ),
                                        TextSpan(
                                          text: "變更日誌: \n",
                                          style: _title,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    toolbarOptions: ToolbarOptions(
                                        copy: true,
                                        selectAll: true,
                                        cut: true)),
                                Container(
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
                                          launch(url);
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
                                  child: Text("不要更新")),
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
                                      Updater.download(info, context);
                                    }
                                  },
                                  child: Text("更新"))
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
                  await utility.OpenUrl(LauncherInfo.HomePageUrl);
                },
                icon: Image.asset("images/Logo.png", scale: 4),
                tooltip: i18n.format("homepage.website")),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    PushTransitions(builder: (context) => SettingScreen()),
                  );
                },
                tooltip: i18n.format("gui.settings")),
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                utility.OpenFileManager(InstanceRootDir);
              },
              tooltip: i18n.format("homepage.instance.folder.open"),
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
              Navigator.push(
                context,
                PushTransitions(builder: (context) => AccountScreen()),
              );
            },
            tooltip: i18n.format("account.title"),
          ),
        ],
      ),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
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
                            String InstancePath = snapshot.data![index].path;
                            if (!InstanceRepository.getInstanceConfigFile(
                                    InstancePath)
                                .existsSync()) {
                              return Container();
                            }
                            Map InstanceConfig =
                                InstanceRepository.getInstanceConfig(
                                    InstancePath);

                            Color color = Colors.white10;
                            var photo;
                            try {
                              if (FileSystemEntity.typeSync(
                                      join(InstancePath, "icon.png")) !=
                                  FileSystemEntityType.notFound) {
                                photo = Image.file(File(join(
                                    snapshot.data![index].path, "icon.png")));
                              } else {
                                photo = Icon(Icons.image);
                              }
                            } on FileSystemException catch (err) {}
                            if ((InstancePath.replaceAll(
                                        join(LauncherFolder.absolute.path,
                                            "instances"),
                                        "")) ==
                                    choose ||
                                start == true) {
                              color = Colors.white30;
                              chooseIndex = index;
                              start = false;
                            }
                            return Card(
                              color: color,
                              child: InkWell(
                                splashColor: Colors.blue.withAlpha(30),
                                onTap: () {
                                  choose = InstancePath.replaceAll(
                                      join(LauncherFolder.absolute.path,
                                          "instances"),
                                      "");
                                  setState(() {});
                                },
                                child: GridTile(
                                  child: Column(
                                    children: [
                                      Expanded(child: photo),
                                      Text(
                                          InstanceConfig["name"] ??
                                              "Name not found",
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Builder(builder: (context) {
                      if (chooseIndex == -1 ||
                          !InstanceRepository.getInstanceConfigFile(
                                  snapshot.data![chooseIndex].path)
                              .existsSync() ||
                          (snapshot.data!.length - 1) < chooseIndex) {
                        return Container();
                      } else {
                        return Builder(
                          builder: (context) {
                            Widget photo;
                            var InstanceConfig = {};
                            String ChooseIndexPath =
                                snapshot.data![chooseIndex].path;
                            InstanceConfig =
                                InstanceRepository.getInstanceConfig(
                                    ChooseIndexPath);
                            if (FileSystemEntity.typeSync(
                                    join(ChooseIndexPath, "icon.png")) !=
                                FileSystemEntityType.notFound) {
                              photo = Image.file(
                                  File(join(ChooseIndexPath, "icon.png")));
                            } else {
                              photo = const Icon(
                                Icons.image,
                                size: 100,
                              );
                            }

                            return Column(
                              children: [
                                Container(
                                  child: photo,
                                  width: 200,
                                  height: 160,
                                ),
                                Text(InstanceConfig["name"] ?? "Name not found",
                                    textAlign: TextAlign.center),
                                SizedBox(height: 12),
                                TextButton(
                                    onPressed: () async {
                                      if (account.getCount() == 0) {
                                        return showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) => AlertDialog(
                                              title: Text(i18n
                                                  .format('gui.error.info')),
                                              content: Text(
                                                  i18n.format('account.null')),
                                              actions: [
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        PushTransitions(
                                                            builder: (context) =>
                                                                AccountScreen()),
                                                      );
                                                    },
                                                    child: Text(i18n
                                                        .format('gui.login')))
                                              ]),
                                        );
                                      }
                                      Map Account = account
                                          .getByIndex(account.getIndex());
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) => FutureBuilder(
                                              future: utility.ValidateAccount(
                                                  Account),
                                              builder: (context,
                                                  AsyncSnapshot snapshot) {
                                                if (snapshot.hasData) {
                                                  if (!snapshot.data) {
                                                    //如果帳號已經過期
                                                    return AlertDialog(
                                                        title: Text(i18n.format(
                                                            'gui.error.info')),
                                                        content: Text(i18n.format(
                                                            'account.expired')),
                                                        actions: [
                                                          ElevatedButton(
                                                              onPressed: () {
                                                                if (Account[
                                                                        'Type'] ==
                                                                    account
                                                                        .Microsoft) {
                                                                  showDialog(
                                                                      barrierDismissible:
                                                                          false,
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) =>
                                                                              RefreshMsTokenScreen());
                                                                } else if (Account[
                                                                        'Type'] ==
                                                                    account
                                                                        .Mojang) {
                                                                  showDialog(
                                                                      barrierDismissible:
                                                                          false,
                                                                      context:
                                                                          context,
                                                                      builder: (context) =>
                                                                          MojangAccount(
                                                                              AccountEmail: Account["Account"]));
                                                                }
                                                              },
                                                              child: Text(
                                                                  i18n.format(
                                                                      'account.again')))
                                                        ]);
                                                  } else {
                                                    return utility.JavaCheck(
                                                        InstanceConfig:
                                                            InstanceConfig,
                                                        hasJava: Builder(
                                                            builder: (context) =>
                                                                CheckAssetsScreen(
                                                                    InstanceDir:
                                                                        Directory(
                                                                            ChooseIndexPath))));
                                                  }
                                                } else {
                                                  return Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                              }));
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
                                      Navigator.push(
                                          context,
                                          PushTransitions(
                                              builder: (context) =>
                                                  EditInstance(
                                                    InstanceRepository
                                                            .getInstanceDir(snapshot
                                                                .data![
                                                                    chooseIndex]
                                                                .path)
                                                        .absolute
                                                        .path,
                                                  )));
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
                                      if (InstanceRepository.getInstanceConfigFile(
                                              "${ChooseIndexPath} (${i18n.format("gui.copy")})")
                                          .existsSync()) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(i18n
                                                  .format("gui.copy.failed")),
                                              content: Text(
                                                  "Can't copy file because file already exists"),
                                              actions: [
                                                TextButton(
                                                  child: Text(i18n
                                                      .format("gui.confirm")),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        copyPathSync(
                                            join(InstanceRootDir.absolute.path,
                                                ChooseIndexPath),
                                            InstanceRepository.getInstanceDir(
                                                    "${ChooseIndexPath} (${i18n.format("gui.copy")})")
                                                .absolute
                                                .path);
                                        var NewInstanceConfig = json.decode(
                                            InstanceRepository
                                                    .getInstanceConfigFile(
                                                        "${ChooseIndexPath} (${i18n.format("gui.copy")})")
                                                .readAsStringSync());
                                        NewInstanceConfig["name"] =
                                            NewInstanceConfig["name"] +
                                                "(${i18n.format("gui.copy")})";
                                        InstanceRepository.getInstanceConfigFile(
                                                "${ChooseIndexPath} (${i18n.format("gui.copy")})")
                                            .writeAsStringSync(
                                                json.encode(NewInstanceConfig));
                                        setState(() {});
                                      }
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
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return CheckDialog(
                                            title: i18n
                                                .format("gui.instance.delete"),
                                            content: i18n.format(
                                                'gui.instance.delete.tips'),
                                            onPressedOK: () {
                                              Navigator.of(context).pop();
                                              try {
                                                InstanceRepository
                                                        .getInstanceDir(snapshot
                                                            .data![chooseIndex]
                                                            .path)
                                                    .deleteSync(
                                                        recursive: true);
                                              } on FileSystemException {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                          title: Text(i18n.format(
                                                              'gui.error.info')),
                                                          content: Text(
                                                              "刪除安裝檔時發生未知錯誤，可能是該資料夾被其他應用程式存取或其他錯誤。"),
                                                          actions: [OkClose()],
                                                        ));
                                              }
                                            },
                                          );
                                        },
                                      );
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
            return RWLLoading(Animations: false);
          }
        },
        future: GetInstanceList(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            PushTransitions(builder: (context) => new VersionSelection()),
          );
        },
        tooltip: i18n.format("version.list.instance.add"),
        child: Icon(Icons.add),
      ),
    );
  }
}

class RWLLoading extends StatefulWidget {
  final bool Animations;

  RWLLoading({
    Key? key,
    required this.Animations,
  }) : super(key: key);

  @override
  State<RWLLoading> createState() => _RWLLoadingState(Animations: Animations);
}

class _RWLLoadingState extends State<RWLLoading> {
  final bool Animations;

  _RWLLoadingState({
    required this.Animations,
  });

  double _Logoopacity = 0;

  @override
  void initState() {
    if (Animations) {
      Future.delayed(Duration(milliseconds: 400)).then((value) => {
            setState(() {
              _Logoopacity = 1;
            })
          });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Animations) {
      return AnimatedOpacity(
        opacity: _Logoopacity,
        duration: Duration(milliseconds: 700),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("images/Logo.png", scale: 0.9),
              SizedBox(
                height: 10,
              ),
              Container(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 45,
                  child: LinearProgressIndicator()),
              SizedBox(
                height: 10,
              ),
              Text(i18n.format('homepage.loading'),
                  style: TextStyle(fontSize: 35))
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}

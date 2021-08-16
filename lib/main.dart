import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Screen/Edit.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:rpmlauncher/Widget/DownloadJava.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Launcher/GameRepository.dart';
import 'Launcher/InstanceRepository.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';
import 'Utility/Config.dart';
import 'Utility/Theme.dart';
import 'Utility/i18n.dart';
import 'Utility/utility.dart';
import 'Widget/CheckAssets.dart';
import 'path.dart';

void main() {
  runApp(LauncherHome());
  i18n.init();
}

class LauncherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeCollection = ThemeCollection(themes: {
      ThemeUtility.Light: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
              primarySwatch: MaterialColor(
            Color.fromRGBO(51, 51, 204, 1.0).value,
            <int, Color>{
              50: Color.fromRGBO(51, 51, 204, 1.0),
              100: Color.fromRGBO(51, 51, 204, 1.0),
              200: Color.fromRGBO(51, 51, 204, 1.0),
              300: Color.fromRGBO(51, 51, 204, 1.0),
              400: Color.fromRGBO(51, 51, 204, 1.0),
              500: Color.fromRGBO(51, 51, 204, 1.0),
              600: Color.fromRGBO(51, 51, 204, 1.0),
              700: Color.fromRGBO(51, 51, 204, 1.0),
              800: Color.fromRGBO(51, 51, 204, 1.0),
              900: Color.fromRGBO(51, 51, 204, 1.0),
            },
          )),
          scaffoldBackgroundColor: Color.fromRGBO(225, 225, 225, 1.0),
          fontFamily: 'font',
          textTheme: new TextTheme(
            bodyText1: new TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color.fromRGBO(51, 51, 204, 1.0)),
          )),
      ThemeUtility.Dark: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'font',
          textTheme: new TextTheme(
              bodyText1: new TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
          ))),
    });
    return DynamicTheme(
        themeCollection: themeCollection,
        defaultThemeId: ThemeUtility.Dark,
        builder: (context, theme) {
          ThemeUtility.UpdateTheme(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'RPMLauncher',
            theme: theme,
            home: MyHomePage(title: 'RPMLauncher'),
          );
        });
  }
}

openHomeUrl() async {
  const url = 'https://www.rpmtw.ga';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MyHomePage extends StatefulWidget {
  var title = "RPMLauncher";

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static Directory LauncherFolder = dataHome;
  Directory InstanceRootDir = GameRepository.getInstanceRootDir();

  Future<List<FileSystemEntity>> GetInstanceList() async {
    var list = await InstanceRootDir.list().toList();
    return list;
  }

  bool isInit = false;
  late Future<List<FileSystemEntity>> InstanceList;

  @override
  void initState() {
    super.initState();
    InstanceList = GetInstanceList();
    InstanceRootDir.watch().listen((event) {
      InstanceList = GetInstanceList();
      setState(() {});
    });
  }

  checkConfigExist() async {
    Directory ConfigFolder = configHome;
    File ConfigFile = GameRepository.getConfigFile();
    File AccountFile = GameRepository.getAccountFile();
    if (!await Directory(ConfigFolder.absolute.path).exists()) {
      Directory(ConfigFolder.absolute.path).createSync();
    }
    if (!await ConfigFile.exists()) {
      ConfigFile.create(recursive: true);
      ConfigFile.writeAsStringSync("{}");
    }
    if (!await AccountFile.exists()) {
      AccountFile.create(recursive: true);
      AccountFile.writeAsStringSync("{}");
    }
  }

  checkInstanceExist() async {
    if (!await Directory(join(LauncherFolder.absolute.path)).exists()) {
      Directory(join(LauncherFolder.absolute.path)).createSync();
    }
    if (!await Directory(InstanceRootDir.absolute.path).exists()) {
      Directory(InstanceRootDir.absolute.path).createSync();
    }
  }

  String? choose;
  late String name;
  bool start = true;

  @override
  Widget build(BuildContext context) {
    InstanceList = GetInstanceList();
    if (!isInit) {
      checkInstanceExist();
      checkConfigExist();
      isInit = true;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0.0,
        title: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.home),
                onPressed: () => openHomeUrl(),
                tooltip: i18n.Format("homepage.website")),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingScreen()),
                  );
                },
                tooltip: i18n.Format("gui.settings")),
            IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                utility.OpenFileManager(InstanceRootDir);
              },
              tooltip: i18n.Format("homepage.instance.folder.open"),
            ),
            IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutScreen()),
                  );
                },
                tooltip: i18n.Format("homepage.about")),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(410.0),
                child: Text(widget.title),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
            tooltip: i18n.Format("account.title"),
          ),
        ],
      ),
      body: FutureBuilder(
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            int chooseIndex = 0;
            return SplitView(
                gripSize: 0,
                initialWeight: 0.7,
                view1: Builder(
                  builder: (context) {
                    return GridView.builder(
                      itemCount: snapshot.data!.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8),
                      physics: ScrollPhysics(),
                      itemBuilder: (context, index) {
                        var InstanceConfig = {};
                        try {
                          InstanceConfig = json.decode(
                              InstanceRepository.getInstanceConfigFile(
                                      snapshot.data![index].path)
                                  .readAsStringSync());
                        } on FileSystemException catch (err) {}
                        Color color = Colors.white10;
                        var photo;
                        try {
                          if (FileSystemEntity.typeSync(join(
                                  snapshot.data![index].path, "icon.png")) !=
                              FileSystemEntityType.notFound) {
                            photo = Image.file(File(
                                join(snapshot.data![index].path, "icon.png")));
                          } else {
                            photo = Icon(Icons.image);
                          }
                        } on FileSystemException catch (err) {}
                        if ((snapshot.data![index].path.replaceAll(
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
                              choose = snapshot.data![index].path.replaceAll(
                                  join(LauncherFolder.absolute.path,
                                      "instances"),
                                  "");
                              setState(() {});
                            },
                            child: GridTile(
                              child: Column(
                                children: [
                                  Expanded(child: photo),
                                  Text(InstanceConfig["name"] ??
                                      "Name not found"),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                view2: Builder(
                  builder: (context) {
                    var photo;
                    var InstanceConfig = {};
                    var ChooseIndexPath = snapshot.data![chooseIndex].path;
                    try {
                      InstanceConfig = json.decode(
                          InstanceRepository.getInstanceConfigFile(
                                  ChooseIndexPath)
                              .readAsStringSync());
                    } on FileSystemException catch (err) {}
                    try {
                      if (FileSystemEntity.typeSync(
                              join(ChooseIndexPath, "icon.png")) !=
                          FileSystemEntityType.notFound) {
                        photo =
                            Image.file(File(join(ChooseIndexPath, "icon.png")));
                      } else {
                        photo = const Icon(
                          Icons.image,
                          size: 100,
                        );
                      }
                    } on FileSystemException catch (err) {}

                    return Column(
                      children: [
                        Container(
                          child: photo,
                          width: 200,
                          height: 160,
                        ),
                        Text(InstanceConfig["name"] ?? "Name not found"),
                        TextButton(
                            onPressed: () {
                              if (account.getCount(account.Mojang) == 0) {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) => AlertDialog(
                                      title:
                                          Text(i18n.Format('gui.error.info')),
                                      content:
                                          Text(i18n.Format('account.null')),
                                      actions: [
                                        ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AccountScreen()),
                                              );
                                            },
                                            child:
                                                Text(i18n.Format('gui.login')))
                                      ]),
                                );
                              } else {
                                var JavaVersion =
                                    InstanceConfig["java_version"].toString();
                                var JavaPath =
                                    Config.GetValue("java_path_${JavaVersion}");
                                if (JavaPath == "" ||
                                    !File(JavaPath).existsSync()) {
                                  //假設Java路徑無效或者不存在就自動下載Java
                                  showDialog(
                                    context: context,
                                    builder: (context) => DownloadJava(
                                        ChooseIndexPath, JavaVersion),
                                  );
                                } else {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) =>
                                        CheckAssetsScreen(ChooseIndexPath),
                                  );
                                }
                              }
                            },
                            child: Text(i18n.Format("gui.instance.launch"))),
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditInstance(
                                            InstanceRepository.getInstanceDir(
                                                    snapshot.data![chooseIndex]
                                                        .path)
                                                .absolute
                                                .path,
                                          )));
                            },
                            child: Text(i18n.Format("gui.edit"))),
                        TextButton(
                            onPressed: () {
                              if (InstanceRepository.getInstanceConfigFile(
                                      "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                  .existsSync()) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title:
                                          Text(i18n.Format("gui.copy.failed")),
                                      content: Text(
                                          "Can't copy file because file already exists"),
                                      actions: [
                                        TextButton(
                                          child:
                                              Text(i18n.Format("gui.confirm")),
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
                                            "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                        .absolute
                                        .path);
                                var NewInstanceConfig = json.decode(
                                    InstanceRepository.getInstanceConfigFile(
                                            "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                        .readAsStringSync());
                                NewInstanceConfig["name"] =
                                    NewInstanceConfig["name"] +
                                        "(${i18n.Format("gui.copy")})";
                                InstanceRepository.getInstanceConfigFile(
                                        "${ChooseIndexPath} (${i18n.Format("gui.copy")})")
                                    .writeAsStringSync(
                                        json.encode(NewInstanceConfig));
                                setState(() {});
                              }
                            },
                            child: Text(i18n.Format("gui.instance.copy"))),
                        TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return CheckDialog(
                                    title: i18n.Format("gui.instance.delete"),
                                    content: "您確定要刪除此安裝檔嗎？ (此動作將無法復原)",
                                    onPressedOK: () {
                                      Navigator.of(context).pop();
                                      InstanceRepository.getInstanceDir(
                                              snapshot.data![chooseIndex].path)
                                          .deleteSync(recursive: true);
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(i18n.Format("gui.instance.delete"))),
                      ],
                    );
                  },
                ),
                viewMode: SplitViewMode.Horizontal);
          } else {
            return Transform.scale(
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Icon(
                        Icons.highlight_off_outlined,
                      ),
                      Text(i18n.Format("homepage.instance.found")),
                    ])),
                scale: 2);
          }
        },
        future: InstanceList,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => new VersionSelection()),
          );
        },
        tooltip: i18n.Format("version.list.instance.add"),
        child: Icon(Icons.add),
      ),
    );
  }
}

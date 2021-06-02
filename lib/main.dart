import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watcher/watcher.dart';

import 'parser.dart';
import 'path.dart';
import 'Screen/About.dart';
import 'Screen/Account.dart';
import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RPMLauncher',
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'font'),
      home: MyHomePage(title: 'RPMLauncher - 輕鬆管理你的Minecraft安裝檔'),
    );
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
  Directory InstanceDir =
      Directory(join(LauncherFolder.absolute.path, "RPMLauncher", "instance"));

  Future<List<FileSystemEntity>> GetInstanceList() async {
    //print(InstanceDir.list().toList());
    var list = await InstanceDir.list().toList();
    return list;
  }

  bool is_init = false;
  late Future<List<FileSystemEntity>> InstanceList;

  @override
  void initState() {
    super.initState();
    InstanceList = GetInstanceList();
    var watcher = DirectoryWatcher(InstanceDir.absolute.path);
    watcher.events.listen((event) {
      InstanceList = GetInstanceList();
      setState(() {});
    });
  }

  String InstanceDir_ =
      join(LauncherFolder.absolute.path, "RPMLauncher", "instance");

  OpenFileManager() async {
    if (Platform.isLinux) {
      await Process.run("xdg-open", [InstanceDir_]);
    } else if (Platform.isWindows) {
      await Process.run("start", [InstanceDir_]);
    } else if (Platform.isMacOS) {
      await Process.run("open", [InstanceDir_]);
    }
  }

  checkConfigExist() async {
    Directory ConfigFolder = configHome;
    File ConfigFile =
        File(join(ConfigFolder.absolute.path, "RPMLauncher", "config.json"));
    File AccountFile =
        File(join(ConfigFolder.absolute.path, "RPMLauncher", "accounts.json"));
    if (!await Directory(join(ConfigFolder.absolute.path, "RPMLauncher"))
        .exists()) {
      Directory(join(ConfigFolder.absolute.path, "RPMLauncher")).createSync();
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
    if (!await Directory(join(LauncherFolder.absolute.path, "RPMLauncher"))
        .exists()) {
      Directory(join(LauncherFolder.absolute.path, "RPMLauncher")).createSync();
    }
    if (!await Directory(InstanceDir.absolute.path).exists()) {
      Directory(InstanceDir.absolute.path).createSync();
    }
  }

  String? choose;
  late String name;
  bool start = true;

  @override
  Widget build(BuildContext context) {
    InstanceList = GetInstanceList();
    if (!is_init) {
      checkInstanceExist();
      checkConfigExist();
      is_init = true;
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RPMLauncher',
        theme: ThemeData(brightness: Brightness.dark, fontFamily: 'font'),
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 0.0,
            title: Row(
              children: <Widget>[
                IconButton(
                    icon: Icon(Icons.home),
                    onPressed: () => openHomeUrl(),
                    tooltip: "開啟我們的官方網站"),
                IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingScreen()),
                      );
                    },
                    tooltip: "設定"),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    OpenFileManager();
                  },
                  tooltip: "開啟安裝檔儲存位置",
                ),
                IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutScreen()),
                      );
                    },
                    tooltip: "關於 RPMLauncher"),
                Builder(
                  builder: (context) {
                    double width = MediaQuery.of(context).size.width;
                    return SizedBox(
                      width: width / 5,
                    );
                  },
                ),
                Text(widget.title),
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
                tooltip: "管理帳號",
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
                        double width = MediaQuery.of(context).size.width;
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8),
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            var cfg_file = CFG(File(join(
                                        InstanceDir.absolute.path,
                                        snapshot.data![index].path,
                                        "instance.cfg"))
                                    .readAsStringSync())
                                .GetParsed();
                            Color color = Colors.white10;
                            var photo;
                            if (FileSystemEntity.typeSync(join(
                                    snapshot.data![index].path,
                                    "minecraft",
                                    "icon.png")) !=
                                FileSystemEntityType.notFound) {
                              photo = Image.file(File(join(
                                  snapshot.data![index].path,
                                  "minecraft",
                                  "icon.png")));
                            } else {
                              photo = Icon(Icons.image);
                            }
                            if ((snapshot.data![index].path.replaceAll(
                                        join(LauncherFolder.absolute.path,
                                            "RPMLauncher", "instance"),
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
                                  choose = snapshot.data![index].path
                                      .replaceAll(
                                          join(LauncherFolder.absolute.path,
                                              "RPMLauncher", "instance"),
                                          "");
                                  setState(() {});
                                },
                                child: GridTile(
                                  child: Column(
                                    children: [
                                      Expanded(child: photo),
                                      Text(
                                          cfg_file["name"] ?? "Name not found"),
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
                        var cfg_file = CFG(File(join(
                                    InstanceDir.absolute.path,
                                    snapshot.data![chooseIndex].path,
                                    "instance.cfg"))
                                .readAsStringSync())
                            .GetParsed();
                        if (FileSystemEntity.typeSync(join(
                                snapshot.data![chooseIndex].path,
                                "minecraft",
                                "icon.png")) !=
                            FileSystemEntityType.notFound) {
                          photo = Image.file(File(join(
                              snapshot.data![chooseIndex].path,
                              "minecraft",
                              "icon.png")));
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
                            Text(cfg_file["name"] ?? "Name not found"),
                            TextButton(
                                onPressed: () {}, child: const Text("啟動")),
                            TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController
                                          rename_controller =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: Text("重新命名"),
                                        content: TextField(
                                          controller: rename_controller,
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('取消'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                              child: const Text('確認'),
                                              onPressed: () {
                                                if (rename_controller
                                                    .text.isNotEmpty) {
                                                  cfg_file["name"] =
                                                      rename_controller.text;
                                                  Navigator.of(context).pop();
                                                  File(join(
                                                          InstanceDir
                                                              .absolute.path,
                                                          snapshot
                                                              .data![
                                                                  chooseIndex]
                                                              .path,
                                                          "instance.cfg"))
                                                      .writeAsStringSync(
                                                          cfg(cfg_file));
                                                } else {}
                                              })
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text("Rename")),
                          ],
                        );
                      },
                    ),
                    viewMode: SplitViewMode.Horizontal);
              } else {
                //return Center(child: CircularProgressIndicator());
                return Transform.scale(
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                          const Icon(
                            Icons.highlight_off_outlined,
                          ),
                          const Text("找不到安裝檔，點擊右下角的 ＋ 來新增安裝檔"),
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
            tooltip: '新增安裝檔',
            child: Icon(Icons.add),
          ),
        ));
  }
}

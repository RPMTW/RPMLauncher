import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watcher/watcher.dart';
import 'package:xdg_directories/xdg_directories.dart';

import 'Screen/Settings.dart';
import 'Screen/VersionSelection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPMLauncher',
      theme: ThemeData(primarySwatch: Colors.indigo, fontFamily: 'font'),
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
  }

  checkInstanceExist() async {
    if (!await Directory(join(LauncherFolder.absolute.path, "RPMLauncher"))
        .exists()) {
      Directory(join(LauncherFolder.absolute.path, "RPMLauncher")).createSync();
    }
    if (!await Directory(InstanceDir.absolute.path).exists()) {
      Directory(InstanceDir.absolute.path).createSync();
    }
    var watcher = DirectoryWatcher(InstanceDir.absolute.path);
    watcher.events.listen((event) {
      InstanceList = GetInstanceList();
      setState(() {});
    });
  }

  String? choose;
  late String name;
  bool start = true;

  @override
  Widget build(BuildContext context) {
    if (!is_init) {
      checkInstanceExist();
      is_init = true;
    }

    return MaterialApp(
        title: 'RPMLauncher',
        theme: ThemeData(primarySwatch: Colors.indigo, fontFamily: 'font'),
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 0.0,
            leading: new IconButton(
                icon: new Icon(Icons.home),
                onPressed: () => openHomeUrl(),
                tooltip: "開啟我們的官方網站"),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(widget.title),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    print("pushed");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => new SettingScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {},
                )
              ],
            ),
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
                            Color color = Colors.white;
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
                              color = Colors.white10;
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
                                      Text(snapshot.data![index].path
                                          .replaceAll(
                                          join(LauncherFolder.absolute.path,
                                              "RPMLauncher", "instance"),
                                          "")
                                          .replaceFirst("/", "")),
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
                              height: 200,
                            ),
                            Text(snapshot.data![chooseIndex].path
                                .replaceAll(
                                join(LauncherFolder.absolute.path,
                                    "RPMLauncher", "instance"),
                                "")
                                .replaceFirst("/", "")),
                            TextButton(
                                onPressed: () {}, child: const Text("啟動"))
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
                    scale: 4);
              }
            },
            future: InstanceList,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new VersionSelection()),
              );
            },
            tooltip: '新增安裝檔',
            child: Icon(Icons.add),
          ),
        ));
  }
}
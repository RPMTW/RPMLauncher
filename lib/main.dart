import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';
import 'package:watcher/watcher.dart';
import 'package:xdg_directories/xdg_directories.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  var title = "launcher";
  static Directory LauncherFolder = dataHome;
  Directory InstanceDir =
      Directory(join(LauncherFolder.absolute.path, "launcher", "instance"));

  Future<List<FileSystemEntity>> GetInstanceList() async {
    //print(InstanceDir.list().toList());
    var list_ = await InstanceDir.list().toList();
    return list_;
  }

  bool is_init = false;
  late Future<List<FileSystemEntity>> InstanceList;

  @override
  void initState() {
    super.initState();
    InstanceList = GetInstanceList();
  }

  checkInstanceExist() async {
    if (!await Directory(join(LauncherFolder.absolute.path, "launcher"))
        .exists()) {
      Directory(join(LauncherFolder.absolute.path, "launcher")).createSync();
    }
    if (!await Directory(InstanceDir.absolute.path).exists()) {
      Directory(InstanceDir.absolute.path).createSync();
    }
    var watcher=DirectoryWatcher(InstanceDir.absolute.path);
    watcher.events.listen((event){
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
        title: title,
        home: Scaffold(
          appBar: AppBar(
              titleSpacing: 0.0,
              title: Builder(builder: (context) {
                return Row(children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.folder),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      print("pushed");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Screen2()),
                      );
                    },
                  ),
                ]);
              })),
          body: FutureBuilder(
            builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData&&snapshot.data!.isNotEmpty) {
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
                                            "launcher", "instance"),
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
                                              "launcher", "instance"),
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
                                                  "launcher", "instance"),
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
                                        "launcher", "instance"),
                                    "")
                                .replaceFirst("/", "")),
                            TextButton(
                                onPressed: () {}, child: const Text("launch"))
                          ],
                        );
                      },
                    ),
                    viewMode: SplitViewMode.Horizontal);
              } else {
                //return Center(child: CircularProgressIndicator());
                return Center(child:Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.highlight_off_outlined,
                      ),
                      const Text("No instance found")
                    ]));
              }
            },
            future: InstanceList,
          ),
        ));
  }
}

class Screen2_ extends State<Screen2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Setting"),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: ListView(
            children: [
              Text(
                "Java",
                textAlign: TextAlign.center,
              )
            ],
          )),
    );
  }
}

class Screen2 extends StatefulWidget {
  @override
  Screen2_ createState() => Screen2_();
}

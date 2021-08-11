import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Mod/CurseForge/Handler.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Widget/ModListView.dart';
import 'package:RPMLauncher/Widget/ModSourceSelection.dart';
import 'package:archive/archive.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:split_view/split_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utility/utility.dart';
import '../main.dart';
import '../path.dart';

class EditInstance_ extends State<EditInstance> {
  late var InstanceConfig;
  late Directory InstanceDir;
  late Directory ScreenshotDir;
  int selectedIndex = 0;
  late List<Widget> WidgetList;
  late Map instanceConfig;
  late int chooseIndex;
  late Directory ModDir;
  TextEditingController NameController = TextEditingController();
  TextEditingController ModSearchController = TextEditingController();
  late Directory WorldRootDir;
  late Directory _ConfigFolder = configHome;
  Color BorderColour = Colors.lightBlue;
  late Widget InstanceImage;
  late String InstanceDirName;

  EditInstance_(InstanceDir_, InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
    InstanceDir = InstanceDir_;
  }

  Future<List<FileSystemEntity>> GetWorldList() async {
    List<FileSystemEntity> WorldList = [];
    WorldRootDir.listSync().toList().forEach((dir) {
      //過濾不是世界的資料夾
      if (dir is Directory &&
          Directory(dir.path)
              .listSync()
              .toList()
              .any((file) => file.path.contains("level.dat"))) {
        WorldList.add(dir);
      }
    });
    return WorldList;
  }

  @override
  void initState() {
    NameController = TextEditingController();
    chooseIndex = 0;
    instanceConfig = InstanceRepository.getInstanceConfig(InstanceDirName);
    ScreenshotDir =
        InstanceRepository.getInstanceScreenshotRootDir(InstanceDirName);
    WorldRootDir = InstanceRepository.getInstanceWorldRootDir(InstanceDirName);
    ModDir = InstanceRepository.getInstanceModRootDir(InstanceDirName);
    NameController.text = instanceConfig["name"];

    utility.CreateFolderOptimization(ScreenshotDir);
    utility.CreateFolderOptimization(WorldRootDir);
    utility.CreateFolderOptimization(ModDir);

    ScreenshotDir.watch().listen((event) {
      setState(() {});
    });
    WorldRootDir.watch().listen((event) {
      setState(() {});
    });

    try {
      if (FileSystemEntity.typeSync(
              join(InstanceDir.absolute.path, "icon.png")) !=
          FileSystemEntityType.notFound) {
        InstanceImage =
            Image.file(File(join(InstanceDir.absolute.path, "icon.png")));
      } else {
        InstanceImage = Icon(Icons.image, size: 150);
      }
    } on FileSystemException catch (err) {}

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetList = [
      ListView(
        children: [
          SizedBox(
            height: 150,
            child: InstanceImage,
          ),
          SizedBox(
            height: 12,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    final file = await FileSelectorPlatform.instance
                        .openFile(acceptedTypeGroups: [
                      XTypeGroup(
                          label: i18n.Format(
                              "edit.instance.homepage.instance.image.file"),
                          extensions: ['jpg', 'png', "gif"])
                    ]);
                    if (file == null) return;
                    File(file.path)
                        .copySync(join(InstanceDir.absolute.path, "icon.png"));
                  },
                  child: Text(
                    i18n.Format("edit.instance.homepage.instance.image"),
                    style: new TextStyle(fontSize: 18),
                  )),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Row(
            children: [
              SizedBox(
                width: 12,
              ),
              Text(
                i18n.Format("edit.instance.homepage.instance.name"),
                style: new TextStyle(fontSize: 18),
              ),
              Expanded(
                child: TextField(
                  controller: NameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText:
                        i18n.Format("edit.instance.homepage.instance.enter"),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: BorderColour, width: 4.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: BorderColour, width: 2.0),
                    ),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (value.length == 0) {
                      BorderColour = Colors.red;
                    } else {
                      BorderColour = Colors.lightBlue;
                    }
                    setState(() {});
                  },
                ),
              ),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                  onPressed: () {
                    instanceConfig["name"] = NameController.text;
                    InstanceRepository.getInstanceConfigFile(InstanceDirName)
                        .writeAsStringSync(json.encode(instanceConfig));
                    setState(() {});
                  },
                  child: Text(
                    i18n.Format("gui.save"),
                    style: new TextStyle(fontSize: 18),
                  )),
              SizedBox(
                width: 12,
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Column(
                        children: [
                          SizedBox(height: 12),
                          Text(i18n.Format("game.version"),
                              style: TextStyle(
                                  fontSize: 20, color: Colors.greenAccent)),
                          Text(instanceConfig["version"],
                              style: TextStyle(fontSize: 30)),
                          SizedBox(height: 12),
                        ],
                      ),
                      SizedBox(width: 12),
                    ],
                  )),
              SizedBox(width: 20),
              Card(
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Column(
                        children: [
                          SizedBox(height: 12),
                          Text(i18n.Format("version.list.mod.loader"),
                              style: TextStyle(
                                  fontSize: 20, color: Colors.greenAccent)),
                          Text(
                              ModLoader().ModLoaderNames[ModLoader()
                                  .GetIndex(instanceConfig["loader"])],
                              style: TextStyle(fontSize: 30)),
                          SizedBox(height: 12),
                        ],
                      ),
                      SizedBox(width: 12),
                    ],
                  )),
              SizedBox(width: 20),
              Card(
                  color: Colors.deepPurpleAccent,
                  child: Row(
                    children: [
                      SizedBox(width: 12),
                      Column(
                        children: [
                          SizedBox(height: 12),
                          Text("模組載入器版本",
                              style: TextStyle(
                                  fontSize: 20, color: Colors.greenAccent)),
                          Text(instanceConfig["loader_version"].toString(),
                              style: TextStyle(fontSize: 30)),
                          SizedBox(height: 12),
                        ],
                      ),
                      SizedBox(width: 12),
                    ],
                  )),
            ],
          )
        ],
      ),
      Stack(
        children: [
          // Mod ListView
          FutureBuilder(
            future: ModDir.list().toList(),
            builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.length == 0) {
                  return Center(
                      child: Text(
                    i18n.Format("edit.instance.mods.list.found"),
                    style: TextStyle(fontSize: 30),
                  ));
                }
                List<FileSystemEntity> files = [];
                snapshot.data!.forEach((file) {
                  if (File(file.path).existsSync() ||
                      path.extension(file.path, 2).contains('.jar') || file is File) {
                    files.add(file);
                  }
                });
                return ModListView(files, ModSearchController, instanceConfig);
              } else if (snapshot.hasError) {
                return Center(
                    child: Text(
                  i18n.Format("edit.instance.mods.list.found"),
                  style: TextStyle(fontSize: 30),
                ));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.add),
                  onPressed: () {
                    if (InstanceRepository.getInstanceConfig(
                            InstanceDirName)["loader"] ==
                        ModLoader().None) {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text(i18n.Format("gui.error.info")),
                                content: Text("原版無法安裝模組"),
                                actions: [
                                  TextButton(
                                    child: Text(i18n.Format("gui.ok")),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ));
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              ModSourceSelection(InstanceDirName));
                    }
                  },
                  tooltip: i18n.Format("gui.mod.add"),
                ),
                SizedBox(
                  width: 10,
                ),
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.folder),
                  onPressed: () {
                    utility.OpenFileManager(ModDir);
                  },
                  tooltip: i18n.Format("edit.instance.mods.folder.open"),
                ), //
                SizedBox(
                  width: 10,
                ),
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {});
                  },
                  tooltip: "重新載入模組頁面",
                ),
              ],
            ),
            bottom: 10,
            right: 10,
          )
        ],
      ),
      Stack(
        children: [
          FutureBuilder(
            future: GetWorldList(),
            builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.length == 0) {
                  return Center(
                      child: Text(
                    "找不到世界",
                    style: TextStyle(fontSize: 30),
                  ));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Color color = Colors.white10;
                    late Widget image;
                    Directory WorldDir = snapshot.data![index] as Directory;
                    try {
                      if (FileSystemEntity.typeSync(
                              File(join(WorldDir.absolute.path, "icon.png"))
                                  .absolute
                                  .path) !=
                          FileSystemEntityType.notFound) {
                        image = Image.file(
                            File(join(WorldDir.absolute.path, "icon.png")),
                            fit: BoxFit.contain);
                      } else {
                        image = Icon(Icons.image, size: 50);
                      }
                    } on FileSystemException catch (err) {}
                    if (chooseIndex == index) {
                      color = Colors.white30;
                    }
                    try {
                      final nbtReader = NbtReader.fromFile(
                          join(WorldDir.absolute.path, "level.dat"));
                      NbtCompound Data = nbtReader
                          .read()
                          .getChildrenByName("Data")[0] as NbtCompound;
                      String WorldName =
                          Data.getChildrenByName("LevelName")[0].value;
                      String WorldVersion =
                          (Data.getChildrenByName("Version")[0] as NbtCompound)
                              .getChildrenByName("Name")[0]
                              .value;
                      int LastPlayed =
                          Data.getChildrenByName("LastPlayed")[0].value;

                      return ListTile(
                          leading: image,
                          tileColor: color,
                          title: Text(
                            WorldName,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                          subtitle: Text(
                              "${i18n.Format("game.version")}: $WorldVersion",
                              textAlign: TextAlign.center),
                          onTap: () {
                            chooseIndex = index;
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      title: Text(
                                          i18n.Format(
                                              "edit.instance.world.info"),
                                          textAlign: TextAlign.center),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              "${i18n.Format("edit.instance.world.name")}: $WorldName"),
                                          Text(
                                              "${i18n.Format("game.version")}: $WorldVersion"),
                                          Text(
                                              "${i18n.Format("edit.instance.world.time")}: ${DateTime.fromMillisecondsSinceEpoch(LastPlayed)}")
                                        ],
                                      ));
                                });
                            setState(() {});
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.folder),
                                onPressed: () {
                                  utility.OpenFileManager(WorldDir);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                            title: Text(
                                                i18n.Format("gui.tips.info")),
                                            content: Text(i18n.Format(
                                                "edit.instance.world.delete")),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                    i18n.Format("gui.cancel")),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                  child: Text(i18n.Format(
                                                      "gui.confirm")),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    WorldDir.deleteSync(
                                                        recursive: true);
                                                  }),
                                            ]);
                                      });
                                },
                              ),
                            ],
                          ));
                    } on FileSystemException catch (err) {
                      return Container();
                    }
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("No world found"));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    final file = await FileSelectorPlatform.instance
                        .openFile(acceptedTypeGroups: [
                      XTypeGroup(
                          label: i18n.Format("edit.instance.world.zip"),
                          extensions: ['zip']),
                    ]);
                    if (file == null) return;
                    final File WorldZipFile = File(file.path);
                    final bytes = await WorldZipFile.readAsBytesSync();
                    final archive = await ZipDecoder().decodeBytes(bytes);
                    bool isParentFolder = archive.files
                        .any((file) => file.toString().startsWith("level.dat"));
                    //只有一層地圖檔案
                    if (isParentFolder) {
                      final WorldDirName =
                          file.name.split(path.extension(file.path)).join("");
                      for (final archiveFile in archive) {
                        final ZipFileName = archiveFile.name;
                        if (archiveFile.isFile) {
                          final data = archiveFile.content as List<int>;
                          await File(join(WorldRootDir.absolute.path,
                              WorldDirName, ZipFileName))
                            ..createSync(recursive: true)
                            ..writeAsBytesSync(data);
                        } else {
                          await Directory(join(WorldRootDir.absolute.path,
                              WorldDirName, ZipFileName))
                            ..create(recursive: true);
                        }
                      }
                    } else {
                      //有兩層資料夾
                      for (final archiveFile in archive) {
                        final ZipFileName = archiveFile.name;
                        if (archiveFile.isFile) {
                          final data = archiveFile.content as List<int>;
                          await File(
                              join(WorldRootDir.absolute.path, ZipFileName))
                            ..createSync(recursive: true)
                            ..writeAsBytesSync(data);
                        } else {
                          await Directory(
                              join(WorldRootDir.absolute.path, ZipFileName))
                            ..create(recursive: true);
                        }
                      }
                    }
                  },
                  tooltip: i18n.Format("edit.instance.world.add"),
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    utility.OpenFileManager(WorldRootDir);
                  },
                  tooltip: i18n.Format("edit.instance.world.folder"),
                ),
              ],
            ),
            bottom: 10,
            right: 10,
          )
        ],
      ),
      Stack(
        children: [
          FutureBuilder(
            future: ScreenshotDir.list().toList(),
            builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                return GridView.builder(
                  itemCount: snapshot.data!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5),
                  itemBuilder: (context, index) {
                    Color color = Colors.white10;
                    var image;
                    late var image_;
                    try {
                      if (FileSystemEntity.typeSync(
                              snapshot.data![index].path) !=
                          FileSystemEntityType.notFound) {
                        image_ = snapshot.data![index];
                        image = Image.file(image_);
                      } else {
                        image = Icon(Icons.image);
                      }
                    } on TypeError {
                      return Container();
                    }
                    ;
                    if (chooseIndex == index) {
                      color = Colors.white30;
                    }
                    return Card(
                      color: color,
                      child: InkWell(
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          chooseIndex = index;
                          setState(() {});
                        },
                        onDoubleTap: () {
                          utility.OpenFileManager(image_);
                          chooseIndex = index;
                          setState(() {});
                        },
                        child: GridTile(
                          child: Column(
                            children: [
                              Expanded(child: image ?? Icon(Icons.image)),
                              Text(image_.path
                                  .toString()
                                  .split(Platform.pathSeparator)
                                  .last),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("No snapshot found"));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          Positioned(
            child: IconButton(
              icon: Icon(Icons.folder),
              onPressed: () {
                utility.OpenFileManager(ScreenshotDir);
              },
              tooltip: "開啟螢幕截圖資料夾",
            ),
            bottom: 10,
            right: 10,
          )
        ],
      )
    ];
    return Scaffold(
      appBar: new AppBar(
        title: Text(i18n.Format("edit.instance.title")),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n.Format("gui.back"),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => LauncherHome()),
            );
          },
        ),
      ),
      body: SplitView(
          view1: ListView(
            children: [
              ListTile(
                title: Text(i18n.Format("homepage")),
                leading: Icon(
                  Icons.home_outlined,
                ),
                onTap: () {
                  selectedIndex = 0;
                  setState(() {});
                },
                tileColor: selectedIndex == 0
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text(i18n.Format("edit.instance.mods.title")),
                leading: Icon(
                  Icons.add_box_outlined,
                ),
                onTap: () {
                  selectedIndex = 1;
                  setState(() {});
                },
                tileColor: selectedIndex == 1
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text(i18n.Format("edit.instance.world.title")),
                leading: Icon(
                  Icons.public_outlined,
                ),
                onTap: () {
                  selectedIndex = 2;
                  setState(() {});
                },
                tileColor: selectedIndex == 2
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text(i18n.Format("edit.instance.screenshot.title")),
                leading: Icon(
                  Icons.screenshot_outlined,
                ),
                onTap: () {
                  selectedIndex = 3;
                  setState(() {});
                },
                tileColor: selectedIndex == 3
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              )
            ],
          ),
          view2: WidgetList[selectedIndex],
          gripSize: 3,
          initialWeight: 0.2,
          viewMode: SplitViewMode.Horizontal),
    );
  }
}

class EditInstance extends StatefulWidget {
  late Directory InstanceDir;
  late String InstanceDirName;

  EditInstance(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
    InstanceDir = InstanceRepository.getInstanceDir(InstanceDirName_);
  }

  @override
  EditInstance_ createState() => EditInstance_(InstanceDir, InstanceDirName);
}

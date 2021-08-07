import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Widget/ModSourceSelection.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:split_view/split_view.dart';

import '../Utility/utility.dart';
import '../main.dart';
import '../path.dart';

class EditInstance_ extends State<EditInstance> {
  late var InstanceConfig;
  late Directory InstanceDir;
  late Directory ScreenshotDir;
  int selectedIndex = 0;
  late List<Widget> WidgetList;
  late Map<String, dynamic> instanceConfig;
  late File instanceConfigFile;
  late int chooseIndex;
  late Directory ModDir;
  TextEditingController name_controller = TextEditingController();
  late Directory WorldDir;
  late File ModIndex_;
  late Map<String, dynamic> ModIndex;
  late Directory _ConfigFolder = configHome;
  late Future<dynamic> ModList;
  Color BorderColour = Colors.lightBlue;
  late List<FileSystemEntity> ModFileList = [];
  late Widget InstanceImage;
  late String InstanceDirName;

  EditInstance_(InstanceDir_, InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
    InstanceDir = InstanceDir_;
  }

  Future<List<FileSystemEntity>> GetScreenshotList() async {
    var list = await ScreenshotDir.list().toList();
    return list;
  }

  Future<List<FileSystemEntity>> GetWorldList() async {
    var list = await WorldDir.list().toList();
    return list;
  }

  static GetModList(InstanceDir) async {
    late Directory _ConfigFolder = configHome;
    var ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));
    var ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    var ModDir = Directory(join(InstanceDir.absolute.path, "mods"));
    List ModList = [];
    int index_ = 0;

    for (FileSystemEntity mod in await ModDir.list().toList()) {
      if (path.extension(mod.path, 2).contains(".jar")) {
        try {
          var ModHash = sha1.convert(File(mod.absolute.path).readAsBytesSync());
          if (ModIndex.containsKey(ModHash)) {
            ModList.add(ModIndex[ModHash]);
          } else {
            var unzipped = ZipDecoder()
                .decodeBytes(File(mod.absolute.path).readAsBytesSync());
            late var mod_type;
            for (final file in unzipped) {
              late var ModJson;
              final filename = file.name;
              if (file.isFile) {
                final data = file.content as List<int>;
                if (filename == "fabric.mod.json") {
                  mod_type="fabric";
                  //Fabric Mod Info File
                  ModJson = jsonDecode(
                      Utf8Decoder(allowMalformed: true).convert(data));
                  ModList.add([
                    "fabric",
                    ModJson["name"],
                    ModJson["description"],
                    ModJson["version"],
                  ]);
                  ModIndex[ModHash.toString()] = [
                    ModJson["name"],
                    ModJson["description"],
                    ModJson["version"],
                  ];
                  index_ = ModList.length - 1;
                  for (var i in unzipped) {
                    if (i.name == ModJson["icon"]) {
                      ModList[index_].add(i.content as List<int>);
                      ModIndex[ModHash.toString()].add(i.content as List<int>);
                    }
                  }
                  break;
                } else if (filename == "mcmod.info") {
                  mod_type="forge";
                  //Forge Mod Info File (1.7.10 -> 1.12.2)
                  ModJson = jsonDecode(
                      Utf8Decoder(allowMalformed: true).convert(data))[0];
                  ModList.add([
                    "forge",
                    ModJson["name"],
                    ModJson["description"],
                    ModJson["version"],
                  ]);
                  index_ = ModList.length - 1;
                  ModIndex[ModHash.toString()] = [
                    ModJson["name"],
                    ModJson["description"],
                    ModJson["version"],
                  ];
                  for (var i in unzipped) {
                    if (i.name == ModJson["logoFile"]) {
                      ModList[index_].add(i.content as List<int>);
                      ModIndex[ModHash.toString()].add(i.content as List<int>);
                    }
                  }
                  break;
                }else{
                  mod_type="unknown";
                }
              }
            }
            if (mod_type=="unknown"){
              ModList.add([
                "unknown",
                mod.absolute.path.split(Platform.pathSeparator).last.replaceFirst(".jar","").replaceFirst(".disable", ""),
                "unknown",
                "unknown",
              ]);
            }
          }
        } on FileSystemException {
          print("A dir detected instead of a file");
        } catch (e) {
          print(e);
        }
      }
    }
    ModIndex_.writeAsStringSync(jsonEncode(ModIndex));
    return ModList;
  }

  Future SpawnGetModList() async {
    ModFileList = await ModDir.list().toList();
    late var mod_list;
    mod_list = await compute(GetModList, InstanceDir);
    return mod_list;
  }

  late bool choose;

  @override
  void initState() {
    chooseIndex = 0;
    instanceConfigFile = File(join(InstanceDir.absolute.path, "instance.json"));
    instanceConfig = jsonDecode(instanceConfigFile.readAsStringSync());
    ScreenshotDir = Directory(join(InstanceDir.absolute.path, "screenshots"));
    WorldDir = Directory(join(InstanceDir.absolute.path, "saves"));
    ModDir = Directory(join(InstanceDir.absolute.path, "mods"));
    name_controller.text = instanceConfig["name"];
    ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }

    ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    utility.CreateFolderOptimization(ScreenshotDir);
    utility.CreateFolderOptimization(WorldDir);
    utility.CreateFolderOptimization(ModDir);
    ModList = SpawnGetModList();

    ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    ScreenshotDir.watch().listen((event) {
      setState(() {});
    });
    WorldDir.watch().listen((event) {
      setState(() {});
    });
    ModDir.watch().listen((event) {
      setState(() {
        ModList = SpawnGetModList();
      });
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
                  controller: name_controller,
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
                    instanceConfig["name"] = name_controller.text;
                    instanceConfigFile
                        .writeAsStringSync(jsonEncode(instanceConfig));
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
          ListTile(
              title: Center(
                  child: Text(
                      "${i18n.Format("game.version")}: ${instanceConfig["version"]}"))),
          ListTile(
            title: Center(
                child: Text(
                    "${i18n.Format("version.list.mod.loader")}: ${ModLoader().ModLoaderNames[ModLoader().GetIndex(instanceConfig["loader"])]}")),
          )
        ],
      ),
      Stack(
        children: [
          FutureBuilder(
            //Mod
            future: ModList,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.length == 0) {
                  return Center(
                      child:
                          Text(i18n.Format("edit.instance.mods.list.found")));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var image;
                    try {
                      image = Image.memory(
                          Uint8List.fromList(snapshot.data[index][4]));
                    } on RangeError {
                      image = Icon(Icons.image);
                    }
                    late FileSystemEntity file;
                    try {
                      file = ModFileList[index];
                    } on RangeError {
                      return Container();
                    }
                    bool ModSwitch = !file.path.endsWith(".disable");
                    return ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  i18n.Format("edit.instance.mods.list.name") +
                                      snapshot.data[index][1]),
                              content: Text(i18n.Format(
                                      "edit.instance.mods.list.description") +
                                  snapshot.data[index][2]),
                            );
                          },
                        );
                        chooseIndex = index;
                        setState(() {});
                      },
                      leading: image,
                      subtitle: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${i18n.Format("edit.instance.mods.list.description")} ${snapshot.data[index][2]}"),
                          Text(i18n.Format("edit.instance.mods.list.version") +
                              snapshot.data[index][3].toString()),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                              value: ModSwitch,
                              onChanged: (value) {
                                setState(() {
                                  if (!file.existsSync()) return;
                                  if (ModSwitch) {
                                    ModSwitch = false;
                                    file.renameSync(
                                        file.absolute.path + ".disable");
                                  } else if (!ModSwitch) {
                                    ModSwitch = true;
                                    file.renameSync(file.absolute.path
                                        .split(".disable")[0]);
                                  }
                                });
                              }),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(i18n.Format("gui.tips.info")),
                                    content: Text("您確定要刪除此模組嗎？ (此動作將無法復原)"),
                                    actions: [
                                      TextButton(
                                        child: Text(i18n.Format("gui.cancel")),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                          child:
                                              Text(i18n.Format("gui.confirm")),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            file.deleteSync(recursive: true);
                                          })
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(
                            builder: (context) {
                              if (snapshot.data[index][0] ==
                                  instanceConfig["loader"]) {
                                return Container();
                              } else {
                                return Positioned(
                                  top: 7,
                                  left: 7,
                                  child: Tooltip(
                                    child: Icon(Icons.warning),
                                    message:
                                        "This mod is a ${snapshot.data[index][0]} mod, this is a ${instanceConfig["loader"]} instance",
                                  ),
                                );
                              }
                            },
                          ),
                          Text(snapshot.data[index][1]),
                        ],
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                    child: Text(i18n.Format("edit.instance.mods.list.found")));
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
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    utility.OpenFileManager(ModDir);
                  },
                  tooltip: i18n.Format("edit.instance.mods.folder.open"),
                ),
              ],
            ),
            bottom: 10,
            right: 10,
          )
        ],
      ),
      FutureBuilder(
        builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10),
              itemBuilder: (context, index) {
                Color color = Colors.white10;
                late var image;
                var world_dir = snapshot.data![index];
                try {
                  if (FileSystemEntity.typeSync(
                          File(join(world_dir.absolute.path, "icon.png"))
                              .absolute
                              .path) !=
                      FileSystemEntityType.notFound) {
                    image = Image.file(
                      File(join(world_dir.absolute.path, "icon.png")),
                      fit: BoxFit.contain,
                    );
                  } else {
                    image = Icon(Icons.image);
                  }
                } on FileSystemException catch (err) {}
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
                      utility.OpenFileManager(
                          Directory(world_dir.absolute.path));
                      chooseIndex = index;
                      setState(() {});
                    },
                    child: GridTile(
                      child: Column(
                        children: [
                          Expanded(child: image),
                          Text(world_dir.absolute.path
                              .split(Platform.pathSeparator)
                              .last), //To Do
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("No world found"));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
        future: GetWorldList(),
      ),
      FutureBuilder(
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
                  if (FileSystemEntity.typeSync(snapshot.data![index].path) !=
                      FileSystemEntityType.notFound) {
                    image_ = snapshot.data![index];
                    image = Image.file(image_);
                  } else {
                    image = Icon(Icons.image);
                  }
                } on TypeError catch (err) {
                  if (err !=
                      "type '_Directory' is not a subtype of type 'File'") {
                    print(err);
                  }
                }

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
        future: GetScreenshotList(),
      ),
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

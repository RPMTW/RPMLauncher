import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:split_view/split_view.dart';

import '../Utility/utility.dart';
import '../main.dart';
import '../path.dart';

class EditInstance_ extends State<EditInstance> {
  late var InstanceConfig;
  late Directory InstanceDir;
  late Directory ScreenshotDir;
  int selectedIndex = 0;
  late List<Widget> widget_list;
  late Map<String, dynamic> instance_config;
  late File instance_config_;
  late int chooseIndex;
  late Directory ModDir;
  TextEditingController name_controller = TextEditingController();
  late Directory WorldDir;
  late File ModIndex_;
  late Map<String, dynamic> ModIndex;
  late Directory _ConfigFolder = configHome;
  late Future<dynamic> ModList;
  Color BorderColour = Colors.lightBlue;

  EditInstance_(InstanceDir_) {
    InstanceDir = Directory(InstanceDir_);
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
    var ModDir = Directory(join(InstanceDir.absolute.path, "mods"));
    var ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));
    var ModIndex = jsonDecode(ModIndex_.readAsStringSync());

    var list = await ModDir.list().toList();
    List mod_list = [];
    int index_ = 0;
    for (FileSystemEntity mod in list) {
      try {
        var mod_sha = sha1.convert(File(mod.absolute.path).readAsBytesSync());
        if (ModIndex.containsKey(mod_sha)) {
          mod_list.add(ModIndex[mod_sha]);
        } else {
          var unzipped = ZipDecoder()
              .decodeBytes(File(mod.absolute.path).readAsBytesSync());
          for (final file in unzipped) {
            late var mod_json;
            final filename = file.name;
            if (file.isFile) {
              final data = file.content as List<int>;
              if (filename == "fabric.mod.json") {
                mod_json =
                    jsonDecode(Utf8Decoder(allowMalformed: true).convert(data));
                mod_list.add([
                  "fabric",
                  mod_json["name"],
                  mod_json["description"],
                ]);
                ModIndex[mod_sha.toString()] = [
                  mod_json["name"],
                  mod_json["description"],
                ];
                index_ = mod_list.length - 1;
                for (var i in unzipped) {
                  if (i.name == mod_json["icon"]) {
                    mod_list[index_].add(i.content as List<int>);
                    ModIndex[mod_sha.toString()].add(i.content as List<int>);
                  }
                }
                break;
              }else if (filename=="mcmod.info"){
                mod_json =
                    jsonDecode(Utf8Decoder(allowMalformed: true).convert(data));
                mod_list.add([
                  "forge",
                  mod_json[0]["name"],
                  mod_json[0]["description"],
                ]);
                index_ = mod_list.length - 1;
                ModIndex[mod_sha.toString()] = [
                  mod_json[0]["name"],
                  mod_json[0]["description"],
                ];
                for (var i in unzipped) {
                  if (i.name == mod_json[0]["logoFile"]) {
                    mod_list[index_].add(i.content as List<int>);
                    ModIndex[mod_sha.toString()].add(i.content as List<int>);
                  }
                }
                print(mod_list);
                break;
              }
            }
          }
        }
      } on FileSystemException  {
        print("A dir detected instead of a file");
      }catch (e){
        print(e);
      }
    }
    ModIndex_.writeAsStringSync(jsonEncode(ModIndex));
    return mod_list;
  }

  Future SpawnGetModList() async {
    var mod_list = await compute(GetModList, InstanceDir);
    return mod_list;
  }

  late bool choose;

  @override
  void initState() {
    chooseIndex = 0;
    instance_config_ = File(join(InstanceDir.absolute.path, "instance.json"));
    instance_config = jsonDecode(instance_config_.readAsStringSync());
    ScreenshotDir = Directory(join(InstanceDir.absolute.path, "screenshots"));
    WorldDir = Directory(join(InstanceDir.absolute.path, "saves"));
    ModDir = Directory(join(InstanceDir.absolute.path, "mods"));
    name_controller.text = instance_config["name"];
    ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }

    ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    ModList = SpawnGetModList();
    utility.CreateFolderOptimization(ScreenshotDir);
    utility.CreateFolderOptimization(WorldDir);
    utility.CreateFolderOptimization(ModDir);

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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget_list = [
      ListView(
        children: [
          Row(
            children: [
              SizedBox(
                width: 12,
              ),
              Text(i18n().Format("edit.instance.homepage.instance.name"),
                style: new TextStyle(fontSize: 18),
              ),
              Expanded(
                child: TextField(
                  controller: name_controller,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: i18n().Format("edit.instance.homepage.instance.enter"),
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
                    instance_config["name"] = name_controller.text;
                    instance_config_
                        .writeAsStringSync(jsonEncode(instance_config));
                    setState(() {});
                  },
                  child: Text(
                    i18n().Format("gui.save"),
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
                      "${i18n().Format("game.version")}: ${instance_config["version"]}"))),
          ListTile(title: Center(child: Text("Modloader: ${instance_config["loader"]}")),)
        ],
      ),
      FutureBuilder(
        //Mod
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) {
                Color color = Colors.white10;
                var image;
                if (chooseIndex == index) {
                  color = Colors.white30;
                }
                try {
                  image =
                      Image.memory(Uint8List.fromList(snapshot.data[index][3]));
                } on RangeError {
                  image = Icon(Icons.image);
                }
                return Card(
                  color: color,
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      chooseIndex = index;
                      //setState(() {});
                    },
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                                i18n().Format("edit.instance.mods.list.name") +
                                    snapshot.data[index][1]),
                            content: Text(i18n().Format(
                                    "edit.instance.mods.list.description") +
                                snapshot.data[index][2]),
                          );
                        },
                      );
                      chooseIndex = index;
                      setState(() {});
                    },
                    child: GridTile(
                      child: Stack(
                          alignment: Alignment.center,
                          children: [
                          Builder(builder: (context) {
                            if (snapshot.data[index][0]==instance_config["loader"]){
                              return Container();
                            }else{
                              return Positioned(
                                top: 7, left: 7,
                                child: Tooltip(child: Icon(Icons.warning),message: "This mod is a ${snapshot.data[index][0]} mod, this is a ${instance_config["loader"]} instance",),
                              );
                            }
                          },),
                          Column(
                            children: [
                              Expanded(child: image),
                              Text(snapshot.data[index][1]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("No mod found"));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
        future: ModList,
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
        title: Text(i18n().Format("edit.instance.title")),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n().Format("gui.back"),
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
                title: Text(i18n().Format("homepage")),
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
                title: Text(i18n().Format("edit.instance.mods.title")),
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
                title: Text(i18n().Format("edit.instance.world.title")),
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
                title: Text(i18n().Format("edit.instance.screenshot.title")),
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
          view2: widget_list[selectedIndex],
          gripSize: 3,
          initialWeight: 0.2,
          viewMode: SplitViewMode.Horizontal),
    );
  }
}

class EditInstance extends StatefulWidget {
  late var InstanceDir;

  EditInstance(InstanceDir_) {
    InstanceDir = InstanceDir_;
  }

  @override
  EditInstance_ createState() => EditInstance_(InstanceDir);
}

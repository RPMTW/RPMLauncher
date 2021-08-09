import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Widget/ModSourceSelection.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  late Directory WorldRootDir;
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
          final ModHash =
              sha1.convert(File(mod.absolute.path).readAsBytesSync());
          if (ModIndex.containsKey(ModHash)) {
            ModList.add(ModIndex[ModHash].add(mod.path));
          } else {
            final unzipped = ZipDecoder()
                .decodeBytes(File(mod.absolute.path).readAsBytesSync());
            late var ModType;
            for (final file in unzipped) {
              var ModJson;
              final filename = file.name;
              if (file.isFile) {
                final data = file.content as List<int>;
                if (filename == "fabric.mod.json") {
                  ModType = ModLoader().Fabric;
                  //Fabric Mod Info File
                  try {
                    ModJson = json.decode(
                        Utf8Decoder(allowMalformed: true).convert(data));

                    int CurseID = 0;
                    final response = await http.post(
                      Uri.parse("${CurseForgeModAPI}/fingerprint"),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode([utility.murmurhash2(File(mod.path))]),
                    );
                    Map body = json.decode(response.body);
                    if (body["exactMatches"].length >= 1) {
                      //如果完全雜湊值匹配
                      CurseID = body["exactMatches"][0]["id"];
                    }

                    ModList.add([
                      ModType,
                      ModJson["name"],
                      ModJson["description"],
                      ModJson["version"],
                      mod.path,
                      CurseID
                    ]);
                    ModIndex[ModHash.toString()] = [
                      ModType,
                      ModJson["name"],
                      ModJson["description"],
                      ModJson["version"],
                      CurseID
                    ];

                    index_ = ModList.length - 1;
                    for (var i in unzipped) {
                      if (i.name == ModJson["icon"]) {
                        ModList[index_].add(i.content as List<int>);
                        ModIndex[ModHash.toString()]
                            .add(i.content as List<int>);
                      }
                    }
                  } on FormatException {
                    ModList.add([
                      ModType,
                      mod.absolute.path
                          .split(Platform.pathSeparator)
                          .last
                          .replaceFirst(".jar", "")
                          .replaceFirst(".disable", ""),
                      "unknown",
                      "unknown",
                      mod.path,
                      "unknown",
                    ]);
                  }
                  break;
                } else if (filename == "mcmod.info") {
                  ModType = ModLoader().Forge;
                  //Forge Mod Info File (1.7.10 -> 1.12.2)
                  ModJson = json.decode(
                      Utf8Decoder(allowMalformed: true).convert(data))[0];
                  ModList.add([
                    ModType,
                    ModJson["name"],
                    ModJson["description"],
                    ModJson["version"],
                    mod.path
                  ]);
                  index_ = ModList.length - 1;
                  ModIndex[ModHash.toString()] = [
                    ModType,
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
                } else {
                  ModType = ModLoader().Unknown;
                }
              }
            }
            if (ModType == ModLoader().Unknown) {
              ModList.add([
                ModType,
                mod.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                "unknown",
                "unknown",
                mod.path
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
    ModList.sort((a, b) {
      return a[1]
          .toString()
          .toLowerCase()
          .compareTo(b[1].toString().toLowerCase());
    });
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
    NameController = TextEditingController();
    chooseIndex = 0;
    instanceConfig = InstanceRepository.getInstanceConfig(InstanceDirName);
    ScreenshotDir =
        InstanceRepository.getInstanceScreenshotRootDir(InstanceDirName);
    WorldRootDir = InstanceRepository.getInstanceWorldRootDir(InstanceDirName);
    ModDir = InstanceRepository.getInstanceModRootDir(InstanceDirName);
    NameController.text = instanceConfig["name"];
    ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }

    ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    utility.CreateFolderOptimization(ScreenshotDir);
    utility.CreateFolderOptimization(WorldRootDir);
    utility.CreateFolderOptimization(ModDir);
    ModList = SpawnGetModList();

    ModIndex = jsonDecode(ModIndex_.readAsStringSync());
    ScreenshotDir.watch().listen((event) {
      setState(() {});
    });
    WorldRootDir.watch().listen((event) {
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
                      child: Text(
                    i18n.Format("edit.instance.mods.list.found"),
                    style: TextStyle(fontSize: 30),
                  ));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var image;
                    try {
                      image = Image.memory(
                          Uint8List.fromList(snapshot.data[index][6]));
                    } on RangeError {
                      image = Icon(Icons.image, size: 50);
                    }
                    late File file;
                    try {
                      file = File(snapshot.data[index][4]);
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
                          Builder(builder: (content) {
                            int CurseID = snapshot.data[index][5];
                            if (CurseID != 0) {
                              return IconButton(
                                onPressed: () async {
                                  Response response = await get(Uri.parse(
                                      "${CurseForgeModAPI}/addon/${CurseID}"));
                                  String PageUrl =
                                      json.decode(response.body)["websiteUrl"];
                                  if (await canLaunch(PageUrl)) {
                                    launch(PageUrl);
                                  } else {
                                    print("Can't open the url $PageUrl");
                                  }
                                },
                                icon: Icon(Icons.open_in_new),
                                tooltip: "在 CurseForge 中檢視此模組",
                              );
                            } else {
                              return Container();
                            }
                          }),
                          Checkbox(
                              value: ModSwitch,
                              onChanged: (value) {
                                if (ModSwitch) {
                                  ModSwitch = false;
                                  file.rename(file.absolute.path + ".disable");
                                } else {
                                  ModSwitch = true;
                                  file.rename(
                                      file.absolute.path.split(".disable")[0]);
                                }
                                setState(() {});
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
      Stack(
        children: [
          FutureBuilder(
            future: GetWorldList(),
            builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.length == 0) {
                  return Center(
                      child: Text(
                    i18n.Format("edit.instance.mods.list.found"),
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dart_minecraft/dart_minecraft.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Model/JvmArgs.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:rpmlauncher/Widget/DeleteFileWidget.dart';
import 'package:rpmlauncher/Widget/FileSwitchBox.dart';
import 'package:rpmlauncher/View/ModListView.dart';
import 'package:rpmlauncher/Widget/ModSourceSelection.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Widget/ShaderpackSourceSelection.dart';
import 'package:rpmlauncher/Widget/WIPWidget.dart';
import 'package:system_info/system_info.dart';

import '../Utility/utility.dart';
import '../main.dart';
import 'Settings.dart';

class EditInstance_ extends State<EditInstance> {
  String get instanceDirName => widget.instanceDirName;
  bool get NewWindow => widget.NewWindow;
  Directory get InstanceDir =>
      InstanceRepository.getInstanceDir(instanceDirName);

  late Directory ScreenshotDir;
  late Directory ResourcePackDir;
  late Directory ShaderpackDir;
  int selectedIndex = 0;
  InstanceConfig get instanceConfig =>
      InstanceRepository.instanceConfig(instanceDirName);
  late int chooseIndex;
  late Directory ModRootDir;
  TextEditingController nameController = TextEditingController();
  late Directory WorldRootDir;
  Color borderColour = Colors.lightBlue;
  late Widget InstanceImage;
  late int JavaVersion = instanceConfig.javaVersion;
  late TextEditingController JavaController = TextEditingController();
  late TextEditingController JvmArgsController = TextEditingController();

  late StreamSubscription<FileSystemEvent> WorldDirEvent;
  late StreamSubscription<FileSystemEvent> ModDirEvent;
  late StreamSubscription<FileSystemEvent> ScreenshotDirEvent;
  StateSetter? setModListState;

  late ThemeData theme;
  late Color PrimaryColor;
  late Color ValidRam;

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
    nameController = TextEditingController();
    chooseIndex = 0;
    ScreenshotDir = InstanceRepository.getScreenshotRootDir(instanceDirName);
    ResourcePackDir =
        InstanceRepository.getResourcePackRootDir(instanceDirName);
    WorldRootDir = InstanceRepository.getWorldRootDir(instanceDirName);
    ModRootDir = InstanceRepository.getModRootDir(instanceDirName);
    nameController.text = instanceConfig.name;
    ShaderpackDir = InstanceRepository.getShaderpackRootDir(instanceDirName);
    if (instanceConfig.javaJvmArgs != null) {
      JvmArgsController.text =
          JvmArgs.fromList(instanceConfig.javaJvmArgs!).args;
    } else {
      JvmArgsController.text = "";
    }
    JavaController.text =
        instanceConfig.toMap()["java_path_$JavaVersion"] ?? "";

    utility.CreateFolderOptimization(ScreenshotDir);
    utility.CreateFolderOptimization(WorldRootDir);
    utility.CreateFolderOptimization(ResourcePackDir);
    utility.CreateFolderOptimization(ShaderpackDir);
    utility.CreateFolderOptimization(ModRootDir);

    ScreenshotDirEvent = ScreenshotDir.watch().listen((event) {
      if (!ScreenshotDir.existsSync()) ScreenshotDirEvent.cancel();
      setState(() {});
    });
    WorldDirEvent = WorldRootDir.watch().listen((event) {
      if (!WorldRootDir.existsSync()) WorldDirEvent.cancel();
      setState(() {});
    });
    ModDirEvent = ModRootDir.watch().listen((event) {
      if (!ModRootDir.existsSync()) ModDirEvent.cancel();
      if (setModListState != null && event is! FileSystemMoveEvent) {
        try {
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
            setModListState!(() {});
          });
        } catch (e) {}
      }
    });
    PrimaryColor = ThemeUtility.getTheme().colorScheme.primary;
    ValidRam = PrimaryColor;

    try {
      if (FileSystemEntity.typeSync(
              join(InstanceDir.absolute.path, "icon.png")) !=
          FileSystemEntityType.notFound) {
        InstanceImage =
            Image.file(File(join(InstanceDir.absolute.path, "icon.png")));
      } else {
        InstanceImage = Icon(Icons.image, size: 150);
      }
    } on FileSystemException {}

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String LastPlayTime;
    if (instanceConfig.lastPlay == null) {
      LastPlayTime = "查無資料";
    } else {
      initializeDateFormatting(Platform.localeName);
      LastPlayTime = DateFormat.yMMMMEEEEd(Platform.localeName)
          .add_jms()
          .format(
              DateTime.fromMillisecondsSinceEpoch(instanceConfig.lastPlay!));
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(i18n.format("edit.instance.title")),
          centerTitle: true,
          leading: Builder(builder: (context) {
            if (NewWindow) {
              return IconButton(
                icon: Icon(Icons.close),
                tooltip: i18n.format("gui.close"),
                onPressed: () {
                  exit(0);
                },
              );
            } else {
              return IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: i18n.format("gui.back"),
                onPressed: () {
                  ScreenshotDirEvent.cancel();
                  WorldDirEvent.cancel();
                  navigator.pop();
                },
              );
            }
          }),
        ),
        body: OptionsView(
            gripSize: 3,
            weights: [0.2],
            optionWidgets: (_setState) {
              return [
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
                                    label: i18n.format(
                                        "edit.instance.homepage.instance.image.file"),
                                    extensions: ['jpg', 'png', "gif"])
                              ]);
                              if (file == null) return;
                              File(file.path).copySync(
                                  join(InstanceDir.absolute.path, "icon.png"));
                            },
                            child: Text(
                              i18n.format(
                                  "edit.instance.homepage.instance.image"),
                              style: TextStyle(fontSize: 18),
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
                          i18n.format("edit.instance.homepage.instance.name"),
                          style: TextStyle(fontSize: 18),
                        ),
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: i18n.format(
                                  "edit.instance.homepage.instance.enter"),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: borderColour, width: 4.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: borderColour, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                borderColour = Colors.red;
                              } else {
                                borderColour = Colors.lightBlue;
                              }
                              _setState(() {});
                            },
                          ),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              instanceConfig.name = nameController.text;
                              _setState(() {});
                            },
                            child: Text(
                              i18n.format("gui.save"),
                              style: TextStyle(fontSize: 18),
                            )),
                        SizedBox(
                          width: 12,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      i18n.format('edit.instance.homepage.info.title'),
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Builder(builder: (context) {
                      final Size size = MediaQuery.of(context).size;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InfoCard(i18n.format("game.version"),
                              instanceConfig.version, size),
                          SizedBox(width: size.width / 60),
                          InfoCard(
                              i18n.format("version.list.mod.loader"),
                              ModLoaderUttily.ModLoaderNames[
                                  ModLoaderUttily.getIndexByLoader(
                                      instanceConfig.loaderEnum)],
                              size),
                          Builder(builder: (context) {
                            if (instanceConfig.loaderEnum !=
                                ModLoaders.vanilla) {
                              //如果不是原版才顯示模組相關內容
                              return Row(
                                children: [
                                  SizedBox(width: size.width / 60),
                                  Stack(
                                    children: [
                                      InfoCard(
                                          i18n.format(
                                              'edit.instance.homepage.info.loader.version'),
                                          instanceConfig.loaderVersion!,
                                          size),
                                      Positioned(
                                        child: IconButton(
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    WiPWidget());
                                          },
                                          icon: Icon(Icons.settings),
                                          iconSize: 25,
                                          tooltip: "更換版本",
                                        ),
                                        top: 5,
                                        right: 10,
                                        // bottom: 10,
                                      )
                                    ],
                                  ),
                                  SizedBox(width: size.width / 60),
                                  InfoCard(
                                      i18n.format(
                                          'edit.instance.homepage.info.mod.count'),
                                      ModRootDir.listSync()
                                          .where((file) =>
                                              extension(file.path, 2)
                                                  .contains('.jar') &&
                                              file is File)
                                          .length
                                          .toString(),
                                      size),
                                ],
                              );
                            } else {
                              return Container();
                            }
                          }),
                          SizedBox(width: size.width / 60),
                          InfoCard(
                              i18n.format(
                                  'edit.instance.homepage.info.play.last'),
                              LastPlayTime,
                              size),
                          SizedBox(width: size.width / 60),
                          InfoCard(
                              i18n.format(
                                  'edit.instance.homepage.info.play.time'),
                              utility.formatDuration(Duration(
                                  milliseconds: instanceConfig.playTime)),
                              size),
                        ],
                      );
                    })
                  ],
                ),
                OptionPage(
                  mainWidget:
                      StatefulBuilder(builder: (context, _setModListState) {
                    setModListState = _setModListState;
                    return FutureBuilder(
                      future: ModRootDir.list().toList(),
                      builder: (context,
                          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                        if (snapshot.hasData) {
                          List<FileSystemEntity> files = snapshot.data!
                              .where((file) =>
                                  path
                                      .extension(file.path, 2)
                                      .contains('.jar') &&
                                  file.existsSync())
                              .toList();
                          if (files.isEmpty) {
                            return Center(
                                child: Text(
                              i18n.format("edit.instance.mods.list.found"),
                              style: TextStyle(fontSize: 30),
                            ));
                          }
                          return ModListView(files, instanceConfig);
                        } else if (snapshot.hasError) {
                          logger.send(snapshot.error);
                          return Text(snapshot.error.toString());
                        } else {
                          return Center(child: RWLLoading());
                        }
                      },
                    );
                  }),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (InstanceRepository.instanceConfig(instanceDirName)
                                .loaderEnum ==
                            ModLoaders.vanilla) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text(i18n.format("gui.error.info")),
                                    content: Text("原版無法安裝模組"),
                                    actions: [
                                      TextButton(
                                        child: Text(i18n.format("gui.ok")),
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
                                  ModSourceSelection(instanceDirName));
                        }
                      },
                      tooltip: i18n.format("gui.mod.add"),
                    ),
                    IconButton(
                      icon: Icon(Icons.folder),
                      onPressed: () {
                        utility.OpenFileManager(ModRootDir);
                      },
                      tooltip: i18n.format("edit.instance.mods.folder.open"),
                    ), //
                  ],
                ),
                Stack(
                  children: [
                    FutureBuilder(
                      future: GetWorldList(),
                      builder: (context,
                          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(
                                child: Text(
                              i18n.format('edit.instance.world.found'),
                              style: TextStyle(fontSize: 30),
                            ));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              late Widget image;
                              Directory WorldDir =
                                  snapshot.data![index] as Directory;
                              try {
                                if (FileSystemEntity.typeSync(File(join(
                                            WorldDir.absolute.path, "icon.png"))
                                        .absolute
                                        .path) !=
                                    FileSystemEntityType.notFound) {
                                  image = Image.file(
                                      File(join(
                                          WorldDir.absolute.path, "icon.png")),
                                      fit: BoxFit.contain);
                                } else {
                                  image = Icon(Icons.image, size: 50);
                                }
                              } on FileSystemException {}
                              try {
                                final nbtReader = NbtReader.fromFile(
                                    join(WorldDir.absolute.path, "level.dat"));
                                NbtCompound Data = nbtReader
                                        .read()
                                        .getChildrenByName("Data")[0]
                                    as NbtCompound;
                                String WorldName =
                                    Data.getChildrenByName("LevelName")[0]
                                        .value;
                                String WorldVersion =
                                    (Data.getChildrenByName("Version")[0]
                                            as NbtCompound)
                                        .getChildrenByName("Name")[0]
                                        .value;
                                int LastPlayed =
                                    Data.getChildrenByName("LastPlayed")[0]
                                        .value;

                                return ListTile(
                                    leading: image,
                                    title: Text(
                                      WorldName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    subtitle: Text(
                                        "${i18n.format("game.version")}: $WorldVersion",
                                        textAlign: TextAlign.center),
                                    onTap: () {
                                      initializeDateFormatting(
                                          Platform.localeName);
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                                title: Text(
                                                    i18n.format(
                                                        "edit.instance.world.info"),
                                                    textAlign:
                                                        TextAlign.center),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        "${i18n.format("edit.instance.world.name")}: $WorldName"),
                                                    Text(
                                                        "${i18n.format("game.version")}: $WorldVersion"),
                                                    Text(
                                                        "${i18n.format("edit.instance.world.time")}: ${DateFormat.yMMMMEEEEd(Platform.localeName).add_jms().format(DateTime.fromMillisecondsSinceEpoch(LastPlayed))}")
                                                  ],
                                                ));
                                          });
                                      _setState(() {});
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
                                        DeleteFileWidget(
                                          tooltip: "刪除世界",
                                          message: i18n.format(
                                              "edit.instance.world.delete"),
                                          onDelete: () {
                                            _setState(() {});
                                          },
                                          fileSystemEntity: WorldDir,
                                        ),
                                      ],
                                    ));
                              } on FileSystemException {
                                return Container();
                              }
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        } else {
                          return Center(child: RWLLoading());
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
                                    label:
                                        i18n.format("edit.instance.world.zip"),
                                    extensions: ['zip']),
                              ]);
                              if (file == null) return;

                              Future<bool> UnWorldZip() async {
                                final File WorldZipFile = File(file.path);
                                final bytes = WorldZipFile.readAsBytesSync();
                                final archive = ZipDecoder().decodeBytes(bytes);
                                bool isParentFolder = archive.files.any(
                                    (file) => file
                                        .toString()
                                        .startsWith("level.dat"));
                                bool isnotParentFolder = archive.files.any(
                                    (file) =>
                                        file.toString().contains("level.dat"));
                                if (isParentFolder) {
                                  //只有一層資料夾
                                  final WorldDirName = file.name
                                      .split(path.extension(file.path))
                                      .join("");
                                  for (final archiveFile in archive) {
                                    final ZipFileName = archiveFile.name;
                                    if (archiveFile.isFile) {
                                      await Future.delayed(
                                          Duration(microseconds: 50));
                                      final data =
                                          archiveFile.content as List<int>;
                                      File(join(WorldRootDir.absolute.path,
                                          WorldDirName, ZipFileName))
                                        ..createSync(recursive: true)
                                        ..writeAsBytesSync(data);
                                    } else {
                                      await Future.delayed(
                                          Duration(microseconds: 50));
                                      Directory(join(WorldRootDir.absolute.path,
                                              WorldDirName, ZipFileName))
                                          .create(recursive: true);
                                    }
                                  }
                                  return true;
                                } else if (isnotParentFolder) {
                                  //有兩層資料夾
                                  for (final archiveFile in archive) {
                                    final ZipFileName = archiveFile.name;
                                    if (archiveFile.isFile) {
                                      await Future.delayed(
                                          Duration(microseconds: 50));
                                      final data =
                                          archiveFile.content as List<int>;
                                      File(join(WorldRootDir.absolute.path,
                                          ZipFileName))
                                        ..createSync(recursive: true)
                                        ..writeAsBytesSync(data);
                                    } else {
                                      await Future.delayed(
                                          Duration(microseconds: 50));
                                      Directory(join(WorldRootDir.absolute.path,
                                              ZipFileName))
                                          .create(recursive: true);
                                    }
                                  }
                                  return true;
                                } else {
                                  //錯誤格式
                                  Navigator.of(context).pop();
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                            contentPadding:
                                                const EdgeInsets.all(16.0),
                                            title: Text(
                                                i18n.format("gui.error.info"),
                                                textAlign: TextAlign.center),
                                            content: Text(
                                                i18n.format(
                                                    'edit.instance.world.add.error'),
                                                textAlign: TextAlign.center),
                                            actions: <Widget>[
                                              TextButton(
                                                child:
                                                    Text(i18n.format("gui.ok")),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              )
                                            ]);
                                      });
                                  return false;
                                }
                              }

                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return FutureBuilder(
                                        future: UnWorldZip(),
                                        builder:
                                            (context, AsyncSnapshot snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data) {
                                            return AlertDialog(
                                                title: Text(i18n
                                                    .format("gui.tips.info")),
                                                content: Text(
                                                    i18n.format(
                                                        'gui.handler.done'),
                                                    textAlign:
                                                        TextAlign.center),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: Text(
                                                        i18n.format("gui.ok")),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                  )
                                                ]);
                                          } else {
                                            return AlertDialog(
                                              title: Text(
                                                  i18n.format("gui.tips.info")),
                                              content: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  RWLLoading(),
                                                  SizedBox(width: 12),
                                                  Text("正在處理世界檔案中，請稍後..."),
                                                ],
                                              ),
                                            );
                                          }
                                        });
                                  });
                            },
                            tooltip: i18n.format("edit.instance.world.add"),
                          ),
                          IconButton(
                            icon: Icon(Icons.folder),
                            onPressed: () {
                              utility.OpenFileManager(WorldRootDir);
                            },
                            tooltip: i18n.format("edit.instance.world.folder"),
                          ),
                        ],
                      ),
                      bottom: 10,
                      right: 10,
                    )
                  ],
                ),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: ScreenshotDir.list().toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                            i18n.format('edit.instance.screenshot.found'),
                            style: TextStyle(fontSize: 30),
                          ));
                        }
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5),
                          itemBuilder: (context, index) {
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
                            return Card(
                              child: InkWell(
                                onTap: () {},
                                onDoubleTap: () {
                                  utility.OpenFileManager(image_);
                                  chooseIndex = index;
                                  _setState(() {});
                                },
                                child: GridTile(
                                  child: Column(
                                    children: [
                                      Expanded(
                                          child: image ?? Icon(Icons.image)),
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
                        return Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.folder),
                      onPressed: () {
                        utility.OpenFileManager(ScreenshotDir);
                      },
                      tooltip: "開啟截圖資料夾",
                    ),
                  ],
                ),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: ShaderpackDir.list()
                        .where(
                            (file) => extension(file.path, 2).contains('.zip'))
                        .toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                            "找不到任何光影",
                            style: TextStyle(fontSize: 30),
                          ));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(basename(snapshot.data![index].path)
                                  .replaceAll('.zip', "")
                                  .replaceAll('.disable', "")),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FileSwitchBox(
                                      file: File(snapshot.data![index].path)),
                                  DeleteFileWidget(
                                      tooltip: "刪除光影",
                                      message: "您確定要刪除此光影嗎？ (此動作將無法復原)",
                                      onDelete: () {
                                        setState(() {});
                                      },
                                      fileSystemEntity: snapshot.data![index])
                                ],
                              ),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      } else {
                        return Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) =>
                                    ShaderpackSourceSelection(instanceDirName));
                          },
                          tooltip: "新增光影",
                        ),
                        IconButton(
                          icon: Icon(Icons.folder),
                          onPressed: () {
                            utility.OpenFileManager(ShaderpackDir);
                          },
                          tooltip: "開啟光影資料夾",
                        ),
                      ],
                    )
                  ],
                ),
                Stack(
                  children: [
                    FutureBuilder(
                      future: ResourcePackDir.list()
                          .where((file) =>
                              extension(file.path, 2).contains('.zip'))
                          .toList(),
                      builder: (context,
                          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(
                                child: Text(
                              "找不到資源包",
                              style: TextStyle(fontSize: 30),
                            ));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              File file = File(snapshot.data![index].path);

                              Future<Archive> unzip() async {
                                final bytes = await file.readAsBytes();
                                return ZipDecoder().decodeBytes(bytes);
                              }

                              return FutureBuilder(
                                  future: unzip(),
                                  builder: (context,
                                      AsyncSnapshot<Archive> snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data!.files.any((_file) =>
                                          _file
                                              .toString()
                                              .startsWith("pack.mcmeta"))) {
                                        Map? packMeta = json.decode(utf8.decode(
                                            snapshot.data!
                                                .findFile('pack.mcmeta')
                                                ?.content));
                                        ArchiveFile? PackImage =
                                            snapshot.data!.findFile('pack.png');
                                        return DecoratedBox(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.white12)),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    if (packMeta != null) {
                                                      return AlertDialog(
                                                        title: Text("資源包資訊",
                                                            textAlign: TextAlign
                                                                .center),
                                                        content: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                                "敘述: ${packMeta['pack']['description']}"),
                                                            Text(
                                                                "資源包格式: ${packMeta['pack']['pack_format']}")
                                                          ],
                                                        ),
                                                        actions: [OkClose()],
                                                      );
                                                    } else {
                                                      return AlertDialog(
                                                          title: Text("資源包資訊"),
                                                          content:
                                                              Text("無任何資訊"));
                                                    }
                                                  });
                                            },
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                ListTile(
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    child: PackImage == null
                                                        ? Icon(Icons.image)
                                                        : Image.memory(
                                                            PackImage.content),
                                                  ),
                                                  title: Text(
                                                      basename(file.path)
                                                          .replaceAll(
                                                              '.zip', "")
                                                          .replaceAll(
                                                              '.disable', "")),
                                                  subtitle: Builder(
                                                      builder: (context) {
                                                    if (packMeta != null) {
                                                      return Text(
                                                          packMeta['pack']
                                                              ['description']);
                                                    } else {
                                                      return Container();
                                                    }
                                                  }),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      FileSwitchBox(file: file),
                                                      DeleteFileWidget(
                                                          tooltip: "刪除資源包",
                                                          message:
                                                              "您確定要刪除此資源包嗎？ (此動作將無法復原)",
                                                          onDelete: () {
                                                            setState(() {});
                                                          },
                                                          fileSystemEntity:
                                                              file)
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        return Container();
                                      }
                                    } else {
                                      return RWLLoading();
                                    }
                                  });
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        } else {
                          return Center(child: RWLLoading());
                        }
                      },
                    ),
                    Positioned(
                      child: IconButton(
                        icon: Icon(Icons.folder),
                        onPressed: () {
                          utility.OpenFileManager(ResourcePackDir);
                        },
                        tooltip: "開啟資源包資料夾",
                      ),
                      bottom: 10,
                      right: 10,
                    )
                  ],
                ),
                ListView(
                  children: [
                    InstanceSettings(context),
                  ],
                ),
              ];
            },
            options: () {
              return ViewOptions([
                ViewOption(
                    title: i18n.format("homepage"),
                    icon: Icon(
                      Icons.home_outlined,
                    ),
                    description:
                        i18n.format('edit.instance.homepage.description')),
                ViewOption(
                    title: i18n.format("edit.instance.mods.title"),
                    icon: Icon(
                      Icons.add_box_outlined,
                    ),
                    description: i18n.format('edit.instance.mods.description')),
                ViewOption(
                    title: i18n.format("edit.instance.world.title"),
                    icon: Icon(
                      Icons.public_outlined,
                    ),
                    description:
                        i18n.format('edit.instance.world.description')),
                ViewOption(
                    title: i18n.format("edit.instance.screenshot.title"),
                    icon: Icon(
                      Icons.screenshot_outlined,
                    ),
                    description:
                        i18n.format('edit.instance.screenshot.description')),
                ViewOption(
                    title: i18n.format('edit.instance.shaderpack.title'),
                    icon: Icon(
                      Icons.hd,
                    ),
                    description:
                        i18n.format('edit.instance.shaderpack.description')),
                ViewOption(
                    title: i18n.format('edit.instance.resourcepack.title'),
                    icon: Icon(LineIcons.penSquare),
                    description:
                        i18n.format('edit.instance.resourcepack.description')),
                ViewOption(
                    title: i18n.format('edit.instance.settings.title'),
                    icon: Icon(Icons.settings),
                    description:
                        i18n.format('edit.instance.settings.description')),
              ]);
            }));
  }

  ListTile InstanceSettings(context) {
    late double RamMB;
    int _ = ((SysInfo.getTotalPhysicalMemory()) / 1024 ~/ 1024);
    _ = _ - _ % 1024;

    RamMB = _.toDouble();

    double nowMaxRamMB =
        instanceConfig.javaMaxRam ?? Config.getValue('java_max_ram');

    TextStyle title_ = TextStyle(
      fontSize: 20.0,
      color: Colors.lightBlue,
    );

    return ListTile(
        title: Column(children: [
      SizedBox(
        height: 20,
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton(
          child: Text(
            "編輯全域設定",
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            navigator.pushNamed(SettingScreen.route);
          },
        ),
        SizedBox(
          width: 20,
        ),
        ElevatedButton(
          child: Text(
            "重設此安裝檔的獨立設定",
            style: TextStyle(fontSize: 18),
          ),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return CheckDialog(
                    title: "重設安裝檔獨立設定",
                    content: '您確定要重設此安裝檔的獨立設定嗎? (此動作將無法復原)',
                    onPressedOK: () {
                      instanceConfig.remove("java_path_$JavaVersion");
                      instanceConfig.javaMaxRam = null;
                      instanceConfig.javaJvmArgs = null;
                      nowMaxRamMB = Config.getValue('java_max_ram');
                      JvmArgsController.text = "";
                      JavaController.text = "";
                      setState(() {});
                      Navigator.pop(context);
                    },
                  );
                });
          },
        ),
      ]),
      SizedBox(
        height: 20,
      ),
      Text(
        "安裝檔獨立設定",
        style: TextStyle(color: Colors.red, fontSize: 30),
      ),
      SizedBox(
        height: 25,
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
            ),
            Expanded(
                child: TextField(
              textAlign: TextAlign.center,
              controller: JavaController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: i18n.format("settings.java.path"),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: PrimaryColor, width: 5.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: PrimaryColor, width: 5.0),
                ),
              ),
            )),
            SizedBox(
              width: 12,
            ),
            ElevatedButton(
                onPressed: () {
                  utility.OpenJavaSelectScreen(context).then((value) {
                    if (value[0]) {
                      instanceConfig.changeValue(
                          "java_path_$JavaVersion", value[1]);
                      JavaController.text = value[1];
                    }
                  });
                },
                child: Text(
                  i18n.format("settings.java.path.select"),
                  style: TextStyle(fontSize: 18),
                )),
          ]),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            i18n.format("settings.java.ram.max"),
            style: title_,
            textAlign: TextAlign.center,
          ),
          Text(
            "${i18n.format("settings.java.ram.physical")} ${RamMB.toStringAsFixed(0)} MB",
          ),
          Slider(
            value: nowMaxRamMB,
            onChanged: (double value) {
              instanceConfig.javaMaxRam = value;
              ValidRam = PrimaryColor;
              nowMaxRamMB = value;
              setState(() {});
            },
            activeColor: ValidRam,
            min: 1024,
            max: RamMB,
            divisions: (RamMB ~/ 1024) - 1,
            label: "${nowMaxRamMB.toInt()} MB",
          ),
        ],
      ),
      Text(
        i18n.format("settings.java.ram.max"),
        style: title_,
        textAlign: TextAlign.center,
      ),
      Text(
        i18n.format('settings.java.jvm.args'),
        style: title_,
        textAlign: TextAlign.center,
      ),
      ListTile(
        title: TextField(
          textAlign: TextAlign.center,
          controller: JvmArgsController,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: PrimaryColor, width: 5.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: PrimaryColor, width: 3.0),
            ),
          ),
          onChanged: (value) async {
            instanceConfig.javaJvmArgs = JvmArgs(args: value).toList();
            setState(() {});
          },
        ),
      ),
    ]));
  }

  Widget InfoCard(String Title, String Values, Size size) {
    return Card(
        color: Colors.deepPurpleAccent,
        child: Row(
          children: [
            SizedBox(width: size.width / 55),
            Column(
              children: [
                SizedBox(height: size.height / 28),
                SizedBox(
                  width: size.width / 15,
                  height: size.height / 25,
                  child: AutoSizeText(Title,
                      style: TextStyle(fontSize: 20, color: Colors.greenAccent),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: size.width / 15,
                  height: size.height / 23,
                  child: AutoSizeText(Values,
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center),
                ),
                SizedBox(height: size.width / 65),
              ],
            ),
            SizedBox(width: size.width / 55),
          ],
        ));
  }
}

class EditInstance extends StatefulWidget {
  final String instanceDirName;
  final bool NewWindow;

  const EditInstance({required this.instanceDirName, this.NewWindow = false});

  @override
  EditInstance_ createState() => EditInstance_();
}

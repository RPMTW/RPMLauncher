import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/UI/ViewOptions.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/screen/instance_independent_setting.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/view/Edit/WorldView.dart';
import 'package:rpmlauncher/view/row_scroll_view.dart';
import 'package:rpmlauncher/widget/DeleteFileWidget.dart';
import 'package:rpmlauncher/widget/FileSwitchBox.dart';
import 'package:rpmlauncher/view/Edit/mods_view.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/view/OptionsView.dart';
import 'package:rpmlauncher/widget/rpmtw_design/rml_text_field.dart';
import 'package:rpmlauncher/widget/rwl_loading.dart';
import 'package:rpmlauncher/widget/ShaderpackSourceSelection.dart';
import 'package:rpmlauncher/widget/WIPWidget.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:window_size/window_size.dart';

import '../util/util.dart';

class EditInstance extends StatefulWidget {
  final String instanceUUID;

  const EditInstance({required this.instanceUUID});

  @override
  State<EditInstance> createState() => _EditInstanceState();
}

class _EditInstanceState extends State<EditInstance> {
  late Instance instance;

  String get instanceUUID => widget.instanceUUID;
  Directory get instanceDir => instance.directory;
  InstanceConfig get instanceConfig => instance.config;

  late Directory screenshotDir;
  late Directory resourcePackDir;
  late Directory shaderpackDir;
  late Directory modRootDir;
  late Directory worldRootDir;

  int selectedIndex = 0;

  late int chooseIndex;

  TextEditingController nameController = TextEditingController();

  late StreamSubscription<FileSystemEvent> screenshotDirEvent;

  late ThemeData theme;
  late Color primaryColor;

  @override
  void initState() {
    instance = Instance.fromUUID(instanceUUID)!;
    setWindowTitle("RPMLauncher - ${instance.name}");
    chooseIndex = 0;
    screenshotDir = InstanceRepository.getScreenshotRootDir(instanceUUID);
    resourcePackDir = InstanceRepository.getResourcePackRootDir(instanceUUID);
    worldRootDir = InstanceRepository.getWorldRootDir(instanceUUID);
    modRootDir = InstanceRepository.getModRootDir(instanceUUID);
    nameController.text = instanceConfig.name;
    shaderpackDir = InstanceRepository.getShaderpackRootDir(instanceUUID);

    primaryColor = ThemeUtil.getTheme().colorScheme.primary;

    super.initState();

    Util.createFolderOptimization(screenshotDir);
    Util.createFolderOptimization(worldRootDir);
    Util.createFolderOptimization(resourcePackDir);
    Util.createFolderOptimization(shaderpackDir);
    Util.createFolderOptimization(modRootDir);

    screenshotDirEvent = screenshotDir.watch().listen((event) {
      if (!screenshotDir.existsSync()) screenshotDirEvent.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    screenshotDirEvent.cancel();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.format("edit.instance.title")),
          centerTitle: true,
          leading: Builder(builder: (context) {
            if (WindowHandler.isMultiWindow) {
              return IconButton(
                icon: const Icon(Icons.close),
                tooltip: I18n.format("gui.close"),
                onPressed: () {
                  WindowHandler.close();
                },
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: I18n.format("gui.back"),
                onPressed: () {
                  screenshotDirEvent.cancel();
                  navigator.pop();
                },
              );
            }
          }),
        ),
        body: OptionsView(
            gripSize: 3,
            optionWidgets: (setState) {
              return [
                ListView(
                  children: [
                    instance.imageWidget(width: 150, height: 150),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (result == null) return;
                              File file = File(result.files.single.path!);
                              file.copySync(
                                  join(instanceDir.absolute.path, "icon.png"));
                            },
                            child: Text(
                              I18n.format(
                                  "edit.instance.homepage.instance.image"),
                              style: const TextStyle(fontSize: 18),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          I18n.format("edit.instance.homepage.instance.name"),
                          style: const TextStyle(fontSize: 18),
                        ),
                        Expanded(
                          child: RMLTextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            hintText: I18n.format(
                                "edit.instance.homepage.instance.enter"),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                instanceConfig.name = nameController.text;
                              } else {
                                ScaffoldMessenger.of(navigator.context)
                                    .showSnackBar(SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(50),
                                        content: I18nText(
                                          "edit.instance.homepage.instance.name.empty",
                                          style: const TextStyle(
                                              fontFamily: 'font'),
                                        )));
                              }
                              setState(() {});
                            },
                            child: Text(
                              I18n.format("gui.save"),
                              style: const TextStyle(fontSize: 18),
                            )),
                        const SizedBox(
                          width: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      I18n.format('edit.instance.homepage.info.title'),
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    RowScrollView(
                      child: Row(
                        children: [
                          infoCard(I18n.format("game.version"),
                              instanceConfig.version),
                          infoCard(I18n.format("version.list.mod.loader"),
                              instanceConfig.loaderEnum.i18nString),
                          Stack(
                            children: [
                              infoCard(
                                  I18n.format(
                                      'edit.instance.homepage.info.loader.version'),
                                  instanceConfig.loaderVersion ?? "",
                                  show: instanceConfig.loaderEnum !=
                                      ModLoader.vanilla),
                              Positioned(
                                top: 5,
                                right: 10,
                                child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => WiPWidget());
                                  },
                                  icon: const Icon(Icons.settings),
                                  iconSize: 25,
                                  tooltip: I18n.format(
                                      'edit.instance.homepage.info.loader.version.change'),
                                ),
                                // bottom: 10,
                              )
                            ],
                          ),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.mod.count'),
                              modRootDir
                                  .listSync()
                                  .where((file) =>
                                      extension(file.path, 2)
                                          .contains('.jar') &&
                                      file is File)
                                  .length
                                  .toString(),
                              show: instanceConfig.loaderEnum !=
                                  ModLoader.vanilla),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.play.last'),
                              instanceConfig.lastPlayLocalString),
                          infoCard(
                              I18n.format(
                                  'edit.instance.homepage.info.play.time'),
                              Util.formatDuration(Duration(
                                  milliseconds: instanceConfig.playTime))),
                        ],
                      ),
                    )
                  ],
                ),
                ModsView(Instance.fromUUID(instanceUUID)!),
                WorldView(worldRootDir: worldRootDir),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: screenshotDir.list().toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: Text(
                            I18n.format('edit.instance.screenshot.found'),
                            style: const TextStyle(fontSize: 30),
                          ));
                        }
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5),
                          controller: ScrollController(),
                          itemBuilder: (context, index) {
                            Widget imageWidget = const Icon(Icons.image);
                            File imageFile = File(snapshot.data![index].path);
                            try {
                              if (imageFile.existsSync()) {
                                imageWidget = Image.file(imageFile);
                              }
                            } on TypeError {
                              return Container();
                            }
                            return Card(
                              child: InkWell(
                                onTap: () {},
                                onDoubleTap: () {
                                  Util.openFileManager(imageFile);
                                  chooseIndex = index;
                                  setState(() {});
                                },
                                child: GridTile(
                                  child: Column(
                                    children: [
                                      Expanded(child: imageWidget),
                                      Text(imageFile.path
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
                        return const Center(child: Text("No snapshot found"));
                      } else {
                        return const Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.folder),
                      onPressed: () {
                        Util.openFileManager(screenshotDir);
                      },
                      tooltip: I18n.format('edit.instance.screenshot.folder'),
                    ),
                  ],
                ),
                OptionPage(
                  mainWidget: FutureBuilder(
                    future: shaderpackDir
                        .list()
                        .where(
                            (file) => extension(file.path, 2).contains('.zip'))
                        .toList(),
                    builder: (context,
                        AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                              child: I18nText(
                            "edit.instance.shaderpack.found.not",
                            style: const TextStyle(fontSize: 30),
                          ));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          controller: ScrollController(),
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
                                      tooltip: I18n.format(
                                          'edit.instance.shaderpack.delete'),
                                      message: I18n.format(
                                          'edit.instance.shaderpack.delete.message'),
                                      onDeleted: () {
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
                        return const Center(child: RWLLoading());
                      }
                    },
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) =>
                                    ShaderpackSourceSelection(instanceUUID));
                          },
                          tooltip: I18n.format('edit.instance.shaderpack.add'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder),
                          onPressed: () {
                            Util.openFileManager(shaderpackDir);
                          },
                          tooltip:
                              I18n.format('edit.instance.shaderpack.folder'),
                        ),
                      ],
                    )
                  ],
                ),
                Stack(
                  children: [
                    FutureBuilder(
                      future: resourcePackDir
                          .list()
                          .where((file) =>
                              extension(file.path, 2).contains('.zip'))
                          .toList(),
                      builder: (context,
                          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(
                                child: I18nText(
                              "edit.instance.resourcepack.found.not",
                              style: const TextStyle(fontSize: 30),
                            ));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            controller: ScrollController(),
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
                                      if (snapshot.data!.files.any((file) =>
                                          file
                                              .toString()
                                              .startsWith("pack.mcmeta"))) {
                                        Map? packMeta;

                                        try {
                                          packMeta = json.decode(utf8.decode(
                                              snapshot.data!
                                                  .findFile('pack.mcmeta')
                                                  ?.content));
                                        } on FormatException {}

                                        ArchiveFile? packImage =
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
                                                        title: I18nText(
                                                            "edit.instance.resourcepack.info.title",
                                                            textAlign: TextAlign
                                                                .center),
                                                        content: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            I18nText(
                                                              "edit.instance.resourcepack.info.description",
                                                              args: {
                                                                "description":
                                                                    packMeta['pack']
                                                                            [
                                                                            'description'] ??
                                                                        ""
                                                              },
                                                            ),
                                                            I18nText(
                                                              "edit.instance.resourcepack.info.format",
                                                              args: {
                                                                "format": packMeta[
                                                                            'pack']
                                                                        [
                                                                        'pack_format']
                                                                    .toString()
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        actions: const [
                                                          OkClose()
                                                        ],
                                                      );
                                                    } else {
                                                      return AlertDialog(
                                                          title: I18nText(
                                                              "edit.instance.resourcepack.info.title"),
                                                          content: I18nText(
                                                              "edit.instance.resourcepack.info.none"));
                                                    }
                                                  });
                                            },
                                            child: Column(
                                              children: [
                                                const SizedBox(
                                                  height: 8,
                                                ),
                                                ListTile(
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    child: packImage == null
                                                        ? const Icon(
                                                            Icons.image)
                                                        : Image.memory(
                                                            packImage.content),
                                                  ),
                                                  title: Text(
                                                      basename(file.path)
                                                          .replaceAll(
                                                              '.zip', "")
                                                          .replaceAll(
                                                              '.disable', "")),
                                                  subtitle: Builder(
                                                      builder: (context) {
                                                    if (packMeta?['pack']
                                                            ['description'] !=
                                                        null) {
                                                      return Text(packMeta![
                                                                  'pack']
                                                              ['description']
                                                          .toString());
                                                    } else {
                                                      return const SizedBox();
                                                    }
                                                  }),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      FileSwitchBox(file: file),
                                                      DeleteFileWidget(
                                                          tooltip: I18n.format(
                                                              'edit.instance.resourcepack.info.delete'),
                                                          message: I18n.format(
                                                              'edit.instance.resourcepack.info.delete.message'),
                                                          onDeleted: () {
                                                            setState(() {});
                                                          },
                                                          fileSystemEntity:
                                                              file)
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
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
                                      return const RWLLoading();
                                    }
                                  });
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        } else {
                          return const Center(child: RWLLoading());
                        }
                      },
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.folder),
                        onPressed: () {
                          Util.openFileManager(resourcePackDir);
                        },
                        tooltip: I18n.format(
                            'edit.instance.resourcepack.info.folder'),
                      ),
                    )
                  ],
                ),
                InstanceIndependentSetting(instanceConfig: instanceConfig),
              ];
            },
            options: () {
              return ViewOptions([
                ViewOptionTile(
                    title: I18n.format("homepage"),
                    icon: const Icon(
                      Icons.home_outlined,
                    ),
                    description:
                        I18n.format('edit.instance.homepage.description')),
                ViewOptionTile(
                    title: I18n.format("edit.instance.mods.title"),
                    icon: const Icon(
                      Icons.add_box_outlined,
                    ),
                    description: I18n.format('edit.instance.mods.description'),
                    show: instanceConfig.loaderEnum != ModLoader.vanilla),
                ViewOptionTile(
                  title: I18n.format("edit.instance.world.title"),
                  icon: const Icon(
                    Icons.public_outlined,
                  ),
                  description: I18n.format('edit.instance.world.description'),
                  show: instanceConfig.sideEnum.isClient,
                ),
                ViewOptionTile(
                  title: I18n.format("edit.instance.screenshot.title"),
                  icon: const Icon(
                    Icons.screenshot_outlined,
                  ),
                  description:
                      I18n.format('edit.instance.screenshot.description'),
                  show: instanceConfig.sideEnum.isClient,
                ),
                ViewOptionTile(
                  title: I18n.format('edit.instance.shaderpack.title'),
                  icon: const Icon(
                    Icons.hd,
                  ),
                  description:
                      I18n.format('edit.instance.shaderpack.description'),
                  show: instanceConfig.sideEnum.isClient,
                ),
                ViewOptionTile(
                  title: I18n.format('edit.instance.resourcepack.title'),
                  icon: const Icon(LineIcons.penSquare),
                  description:
                      I18n.format('edit.instance.resourcepack.description'),
                  show: instanceConfig.sideEnum.isClient,
                ),
                ViewOptionTile(
                    title: I18n.format('edit.instance.settings.title'),
                    icon: const Icon(Icons.settings),
                    description:
                        I18n.format('edit.instance.settings.description')),
              ]);
            }));
  }

  Widget infoCard(String title, String values, {bool show = true}) {
    if (show) {
      return Stack(children: [
        Card(
          margin: const EdgeInsets.all(8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.deepPurpleAccent,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, color: Colors.greenAccent),
                      textAlign: TextAlign.center),
                  Text(values,
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                ],
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ]);
    } else {
      return const SizedBox.shrink();
    }
  }
}

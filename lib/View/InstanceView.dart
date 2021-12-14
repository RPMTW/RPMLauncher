import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/Background.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:split_view/split_view.dart';

class InstanceView extends StatefulWidget {
  final MinecraftSide side;

  const InstanceView({Key? key, required this.side}) : super(key: key);

  @override
  _InstanceViewState createState() => _InstanceViewState();
}

class _InstanceViewState extends State<InstanceView> {
  Directory instanceRootDir = GameRepository.getInstanceRootDir();
  int chooseIndex = -1;

  @override
  void initState() {
    super.initState();
    instanceRootDir.watch().listen((event) {
      try {
        setState(() {});
      } catch (e) {}
    });
  }

  Future<List<Instance>> getInstanceList() async {
    List<Instance> instances = [];
    List<FileSystemEntity> dirs = await instanceRootDir.list().toList();

    for (FileSystemEntity dir in dirs) {
      if (dir is Directory) {
        List<FileSystemEntity> _files = await dir.list().toList();
        if (_files.any((file) => basename(file.path) == "instance.json")) {
          Instance instance = Instance(InstanceRepository.getUUIDByDir(dir));
          if (instance.config.sideEnum == widget.side) {
            instances.add(instance);
          }
        }
      }
    }

    instances.sort((a, b) => a.name.compareTo(b.name));
    return instances;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, AsyncSnapshot<List<Instance>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isNotEmpty) {
            return Background(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: SplitView(
                    gripSize: 0,
                    controller: SplitViewController(weights: [0.7]),
                    children: [
                      Builder(
                        builder: (context) {
                          return GridView.builder(
                            itemCount: snapshot.data!.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8),
                            physics: ScrollPhysics(),
                            itemBuilder: (context, index) {
                              try {
                                Instance instance = snapshot.data![index];
            
                                return ContextMenuArea(
                                  items: [
                                    ListTile(
                                      title: I18nText("gui.instance.launch"),
                                      subtitle: I18nText(
                                          "gui.instance.launch.subtitle"),
                                      onTap: () {
                                        navigator.pop();
                                        instance.launcher();
                                      },
                                    ),
                                    ListTile(
                                      title: I18nText("gui.edit"),
                                      subtitle: I18nText("gui.edit.subtitle"),
                                      onTap: () {
                                        navigator.pop();
                                        instance.edit();
                                      },
                                    ),
                                    ListTile(
                                      title: I18nText("gui.folder"),
                                      subtitle: I18nText(
                                          "homepage.instance.contextmenu.folder.subtitle"),
                                      onTap: () {
                                        navigator.pop();
                                        instance.openFolder();
                                      },
                                    ),
                                    ListTile(
                                      title: I18nText("gui.copy"),
                                      subtitle: I18nText(
                                          "homepage.instance.contextmenu.copy.subtitle"),
                                      onTap: () {
                                        navigator.pop();
                                        instance.copy();
                                      },
                                    ),
                                    ListTile(
                                      title: I18nText('gui.delete',
                                          style: TextStyle(color: Colors.red)),
                                      subtitle: I18nText(
                                          "homepage.instance.contextmenu.delete.subtitle"),
                                      onTap: () {
                                        navigator.pop();
                                        instance.delete();
                                      },
                                    )
                                  ],
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Card(
                                      child: InkWell(
                                        onTap: () {
                                          chooseIndex = index;
                                          setState(() {});
                                        },
                                        child: Column(
                                          children: [
                                            Expanded(
                                                child: instance.imageWidget),
                                            Text(instance.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } on FileSystemException {
                                return SizedBox.shrink();
                              } catch (e, stackTrace) {
                                logger.error(ErrorType.unknown, e,
                                    stackTrace: stackTrace);
                                return SizedBox.shrink();
                              }
                            },
                          );
                        },
                      ),
                      Builder(builder: (context) {
                        if (chooseIndex == -1 ||
                            (snapshot.data!.length - 1) < chooseIndex ||
                            !InstanceRepository.instanceConfigFile(
                                    snapshot.data![chooseIndex].path)
                                .existsSync()) {
                          return Container();
                        } else {
                          Instance instance = snapshot.data![chooseIndex];
            
                          return SingleChildScrollView(
                            controller: ScrollController(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: SizedBox(
                                    child: instance.imageWidget,
                                    width: 150,
                                    height: 150,
                                  ),
                                ),
                                Text(instance.name,
                                    textAlign: TextAlign.center),
                                SizedBox(height: 12),
                                _InstanceActionButton(
                                    icon: Icon(
                                      Icons.play_arrow,
                                    ),
                                    label: Text(
                                        I18n.format("gui.instance.launch")),
                                    onPressed: () => instance.launcher()),
                                SizedBox(height: 12),
                                _InstanceActionButton(
                                  onPressed: () {
                                    instance.edit();
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                  ),
                                  label: Text(I18n.format("gui.edit")),
                                ),
                                SizedBox(height: 12),
                                _InstanceActionButton(
                                  icon: Icon(
                                    Icons.folder,
                                  ),
                                  onPressed: () {
                                    instance.openFolder();
                                  },
                                  label: Text(I18n.format("gui.folder")),
                                ),
                                SizedBox(height: 12),
                                _InstanceActionButton(
                                  icon: Icon(
                                    Icons.content_copy,
                                  ),
                                  onPressed: () {
                                    instance.copy();
                                  },
                                  label: Text(I18n.format("gui.copy")),
                                ),
                                SizedBox(height: 12),
                                _InstanceActionButton(
                                  icon: Icon(
                                    Icons.delete,
                                  ),
                                  label: Text(I18n.format("gui.delete")),
                                  onPressed: () {
                                    instance.delete();
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ],
                    viewMode: SplitViewMode.Horizontal),
              ),
            );
          } else {
            return Background(
              child: Transform.scale(
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        Icon(Icons.sports_esports, color: Colors.white),
                        Text(I18n.format("homepage.instance.found"),
                            style: TextStyle(color: Colors.white)),
                        Text(I18n.format("homepage.instance.found.tips"),
                            style: TextStyle(color: Colors.white))
                      ])),
                  scale: 2),
            );
          }
        } else {
          return RWLLoading(
            animations: false,
            logo: true,
          );
        }
      },
      future: getInstanceList(),
    );
  }
}

class _InstanceActionButton extends StatelessWidget {
  const _InstanceActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Icon icon;
  final Text label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icon,
      ),
      label: SizedBox(
        width: 65,
        height: 20,
        child: Text(
          label.data!,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: label.style?.fontSize ?? 15),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

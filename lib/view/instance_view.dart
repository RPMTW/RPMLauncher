import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/widget/rpmtw_design/Background.dart';
import 'package:rpmlauncher/widget/rwl_loading.dart';
import 'package:split_view/split_view.dart';

class InstanceView extends StatefulWidget {
  final MinecraftSide side;

  const InstanceView({Key? key, required this.side}) : super(key: key);

  @override
  State<InstanceView> createState() => _InstanceViewState();
}

class _InstanceViewState extends State<InstanceView> {
  Directory instanceRootDir = GameRepository.getInstanceRootDir();
  int chooseIndex = -1;

  @override
  void initState() {
    super.initState();
    instanceRootDir.watch().listen((event) async {
      try {
        await Future.delayed(const Duration(milliseconds: 250));
        Directory dir = Directory(event.path);
        bool check2 = event.isDirectory &&
            (await dir.list().toList())
                .any((e) => basename(e.path) == 'instance.json');

        if (mounted &&
            (event.path.contains('instance.json') ||
                check2 ||
                event is FileSystemDeleteEvent)) {
          setState(() {});
        }
      } catch (e) {}
    });
  }

  Future<List<Instance>> getInstanceList() async {
    List<Instance> instances = [];
    List<FileSystemEntity> dirs = await instanceRootDir.list().toList();

    for (FileSystemEntity dir in dirs) {
      if (dir is Directory) {
        List<FileSystemEntity> files = await dir.list().toList();
        if (files.any((file) => basename(file.path) == 'instance.json')) {
          Instance? instance =
              Instance.fromUUID(InstanceRepository.getUUIDByDir(dir));
          if (instance != null && instance.config.sideEnum == widget.side) {
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
    return Background(
      child: FutureBuilder(
        builder: (context, AsyncSnapshot<List<Instance>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              return SplitView(
                  gripSize: 0,
                  controller: SplitViewController(weights: [0.7]),
                  viewMode: SplitViewMode.Horizontal,
                  children: [
                    Builder(
                      builder: (context) {
                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 8),
                          physics: const ScrollPhysics(),
                          itemBuilder: (context, index) {
                            try {
                              Instance instance = snapshot.data![index];

                              return ContextMenuArea(
                                builder: (context) => [
                                  ListTile(
                                    title: I18nText('gui.instance.launch'),
                                    subtitle: I18nText(
                                        'gui.instance.launch.subtitle'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      instance.launch(context);
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText('gui.edit'),
                                    subtitle: I18nText('gui.edit.subtitle'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      instance.edit();
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText('gui.folder'),
                                    subtitle: I18nText(
                                        'homepage.instance.contextmenu.folder.subtitle'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      instance.openFolder();
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText('gui.copy'),
                                    subtitle: I18nText(
                                        'homepage.instance.contextmenu.copy.subtitle'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      instance.copy();
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText('gui.delete',
                                        style:
                                            const TextStyle(color: Colors.red)),
                                    subtitle: I18nText(
                                        'homepage.instance.contextmenu.delete.subtitle'),
                                    onTap: () {
                                      Navigator.pop(context);
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Column(
                                          children: [
                                            Expanded(
                                                child: instance.imageWidget(
                                                    expand: true)),
                                            Text(instance.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } on FileSystemException {
                              return const SizedBox.shrink();
                            } catch (e, stackTrace) {
                              logger.error(ErrorType.unknown, e,
                                  stackTrace: stackTrace);
                              return const SizedBox.shrink();
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
                              const SizedBox(
                                height: 10,
                              ),
                              instance.imageWidget(width: 100, height: 100),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(instance.name,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              _InstanceActionButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                  ),
                                  label:
                                      Text(I18n.format('gui.instance.launch')),
                                  onPressed: () => instance.launch(context)),
                              const SizedBox(height: 12),
                              _InstanceActionButton(
                                onPressed: () {
                                  instance.edit();
                                },
                                icon: const Icon(
                                  Icons.edit,
                                ),
                                label: Text(I18n.format('gui.edit')),
                              ),
                              const SizedBox(height: 12),
                              _InstanceActionButton(
                                icon: const Icon(
                                  Icons.folder,
                                ),
                                onPressed: () {
                                  instance.openFolder();
                                },
                                label: Text(I18n.format('gui.folder')),
                              ),
                              const SizedBox(height: 12),
                              _InstanceActionButton(
                                icon: const Icon(
                                  Icons.content_copy,
                                ),
                                onPressed: () {
                                  instance.copy();
                                },
                                label: Text(I18n.format('gui.copy')),
                              ),
                              const SizedBox(height: 12),
                              _InstanceActionButton(
                                icon: const Icon(
                                  Icons.delete,
                                ),
                                label: Text(I18n.format('gui.delete')),
                                onPressed: () {
                                  instance.delete();
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    }),
                  ]);
            } else {
              return Transform.scale(
                  scale: 2,
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        const Icon(Icons.sports_esports, color: Colors.white),
                        Text(I18n.format('homepage.instance.found'),
                            style: const TextStyle(color: Colors.white)),
                        Text(I18n.format('homepage.instance.found.tips'),
                            style: const TextStyle(color: Colors.white))
                      ])));
            }
          } else {
            return const RWLLoading();
          }
        },
        future: getInstanceList(),
      ),
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
    return ElevatedButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label.data!,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }
}

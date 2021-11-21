import 'dart:io';
import 'dart:ui';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart';
import 'package:split_view/split_view.dart';

class InstanceView extends StatefulWidget {
  const InstanceView({Key? key}) : super(key: key);

  @override
  _InstanceViewState createState() => _InstanceViewState();
}

class _InstanceViewState extends State<InstanceView> {
  Directory instanceRootDir = GameRepository.getInstanceRootDir();
  int chooseIndex = -1;

  @override
  void initState() {
    instanceRootDir.watch().listen((event) {
      try {
        setState(() {});
      } catch (e) {}
    });
    super.initState();
  }

  Future<List<Instance>> getInstanceList() async {
    List<Instance> instances = [];

    await instanceRootDir.list().forEach((fse) {
      if (fse is Directory &&
          fse
              .listSync()
              .any((file) => basename(file.path) == "instance.json")) {
        instances.add(Instance(InstanceRepository.getUUIDByDir(fse)));
      }
    });
    return instances;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Image.asset(
          "assets/images/background.png",
          fit: BoxFit.fill,
        ),
      ),
      Opacity(
        opacity: 0.18,
        child: ColoredBox(
          color: Colors.black,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
        ),
      ),
      FutureBuilder(
        builder: (context, AsyncSnapshot<List<Instance>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isNotEmpty) {
              return SizedBox(
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

                                late Widget photo;
                                if (File(join(instance.path, "icon.png"))
                                    .existsSync()) {
                                  try {
                                    photo = Image.file(
                                        File(join(instance.path, "icon.png")));
                                  } catch (err) {
                                    photo = Icon(
                                      Icons.image,
                                    );
                                  }
                                } else {
                                  photo = Icon(
                                    Icons.image,
                                  );
                                }

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
                                  child: Card(
                                    child: InkWell(
                                      onTap: () {
                                        chooseIndex = index;
                                        setState(() {});
                                      },
                                      child: Column(
                                        children: [
                                          Expanded(child: photo),
                                          Text(instance.name,
                                              textAlign: TextAlign.center),
                                        ],
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

                          return Builder(
                            builder: (context) {
                              late Widget photo;

                              if (FileSystemEntity.typeSync(
                                      join(instance.path, "icon.png")) !=
                                  FileSystemEntityType.notFound) {
                                photo = Image.file(
                                    File(join(instance.path, "icon.png")));
                              } else {
                                photo = const Icon(
                                  Icons.image,
                                  size: 100,
                                );
                              }

                              return Column(
                                children: [
                                  SizedBox(
                                    child: photo,
                                    width: 200,
                                    height: 160,
                                  ),
                                  Text(instance.name,
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.play_arrow,
                                    ),
                                    label: Text(
                                        I18n.format("gui.instance.launch")),
                                    onPressed: () {
                                      instance.launcher();
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      instance.edit();
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                    ),
                                    label: Text(I18n.format("gui.edit")),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.content_copy,
                                    ),
                                    onPressed: () {
                                      instance.copy();
                                    },
                                    label: Text(I18n.format("gui.copy")),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.delete,
                                    ),
                                    label: Text(I18n.format("gui.delete")),
                                    onPressed: () {
                                      instance.delete();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }),
                    ],
                    viewMode: SplitViewMode.Horizontal),
              );
            } else {
              return Transform.scale(
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        Icon(
                          Icons.today,
                        ),
                        Text(I18n.format("homepage.instance.found")),
                        Text(I18n.format("homepage.instance.found.tips"))
                      ])),
                  scale: 2);
            }
          } else {
            return RWLLoading(
              animations: false,
              logo: true,
            );
          }
        },
        future: getInstanceList(),
      ),
    ]);
  }
}

import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
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
        instances
            .add(Instance(InstanceRepository.getinstanceDirNameByDir(fse)));
      }
    });
    return instances;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
                          shrinkWrap: true,
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
                                    title: Text("資料夾"),
                                    subtitle: Text("開啟安裝檔的資料夾位置"),
                                    onTap: () {
                                      navigator.pop();
                                      instance.openFolder();
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText("gui.copy"),
                                    subtitle: Text("複製此安裝檔"),
                                    onTap: () {
                                      navigator.pop();
                                      instance.copy();
                                    },
                                  ),
                                  ListTile(
                                    title: I18nText('gui.delete',
                                        style: TextStyle(color: Colors.red)),
                                    subtitle: Text("刪除此安裝檔"),
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
                                TextButton(
                                    onPressed: () {
                                      instance.launcher();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_arrow,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                            I18n.format("gui.instance.launch")),
                                      ],
                                    )),
                                SizedBox(height: 12),
                                TextButton(
                                    onPressed: () {
                                      instance.edit();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                        ),
                                        SizedBox(width: 5),
                                        Text(I18n.format("gui.edit")),
                                      ],
                                    )),
                                SizedBox(height: 12),
                                TextButton(
                                    onPressed: () {
                                      instance.copy();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.content_copy,
                                        ),
                                        SizedBox(width: 5),
                                        Text(I18n.format("gui.copy")),
                                      ],
                                    )),
                                SizedBox(height: 12),
                                TextButton(
                                    onPressed: () {
                                      instance.delete();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                        ),
                                        SizedBox(width: 5),
                                        Text(I18n.format("gui.delete")),
                                      ],
                                    )),
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
    );
  }
}

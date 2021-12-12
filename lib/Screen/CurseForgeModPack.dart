import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class _CurseForgeModPackState extends State<CurseForgeModPack> {
  late List beforeList = [];
  late int index = 0;

  TextEditingController searchController = TextEditingController();
  ScrollController modPackScrollController = ScrollController();

  List<String> sortItems = [
    I18n.format("edit.instance.mods.sort.curseforge.featured"),
    I18n.format("edit.instance.mods.sort.curseforge.popularity"),
    I18n.format("edit.instance.mods.sort.curseforge.update"),
    I18n.format("edit.instance.mods.sort.curseforge.name"),
    I18n.format("edit.instance.mods.sort.curseforge.author"),
    I18n.format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String sortItem =
      I18n.format("edit.instance.mods.sort.curseforge.popularity");

  List<String> versionItems = [];
  String versionItem = I18n.format('modpack.all_version');

  @override
  void initState() {
    modPackScrollController.addListener(() {
      if (modPackScrollController.position.maxScrollExtent ==
          modPackScrollController.position.pixels) {
        //如果滑動到底部
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(I18n.format('modpack.curseforge.title'),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          RowScrollView(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(I18n.format('modpack.search')),
                SizedBox(
                  width: 12,
                ),
                SizedBox(
                    width: 500,
                    child: RPMTextField(
                      textAlign: TextAlign.center,
                      controller: searchController,
                      hintText: I18n.format('modpack.search.hint'),
                    )),
                SizedBox(
                  width: 12,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepPurpleAccent)),
                  onPressed: () {
                    setState(() {
                      index = 0;
                      beforeList = [];
                    });
                  },
                  child: Text(I18n.format("gui.search")),
                ),
                SizedBox(
                  width: 12,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(I18n.format("edit.instance.mods.sort")),
                    DropdownButton<String>(
                      value: sortItem,
                      onChanged: (String? newValue) {
                        setState(() {
                          sortItem = newValue!;
                          index = 0;
                          beforeList = [];
                        });
                      },
                      items: sortItems
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                SizedBox(
                  width: 12,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(I18n.format("game.version")),
                    FutureBuilder(
                        future: CurseForgeHandler.getMCVersionList(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            versionItems = [I18n.format('modpack.all_version')];
                            versionItems.addAll(snapshot.data);

                            return DropdownButton<String>(
                              value: versionItem,
                              onChanged: (String? newValue) {
                                setState(() {
                                  versionItem = newValue!;
                                  index = 0;
                                  beforeList = [];
                                });
                              },
                              items: versionItems.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            return Center(child: RWLLoading());
                          }
                        })
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: CurseForgeHandler.getModPackList(
                versionItem,
                searchController,
                beforeList,
                index,
                sortItems.indexOf(sortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.isEmpty) {
                  return Text(I18n.format('modpack.found'),
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                beforeList = snapshot.data;
                index++;
                return ListView.builder(
                  controller: modPackScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String modPackName = data["name"];
                    String modDescription = data["summary"];
                    String pageUrl = data["websiteUrl"];

                    return ListTile(
                      leading: CurseForgeHandler.getAddonIconWidget(
                          data['attachments']),
                      title: Text(modPackName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              Uttily.openUri(pageUrl);
                            },
                            icon: Icon(Icons.open_in_browser),
                            tooltip:
                                I18n.format("edit.instance.mods.page.open"),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          _InstallButton(data: data, versionItem: versionItem),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: I18nText(
                                "modpack.name",
                                args: {"name": modPackName},
                              ),
                              content: I18nText(
                                "modpack.description",
                                args: {"description": modDescription},
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return Center(child: RWLLoading());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _InstallButton extends StatelessWidget {
  const _InstallButton({
    Key? key,
    required this.data,
    required this.versionItem,
  }) : super(key: key);

  final Map data;
  final String versionItem;

  @override
  Widget build(BuildContext context) {
    int curseID = data["id"];

    return ElevatedButton(
      child: Text(I18n.format("gui.install")),
      onPressed: () {
        List files = [];
        int tempFileID = 0;
        data["gameVersionLatestFiles"].forEach((file) {
          //過濾相同檔案ID
          if (file["projectFileId"] != tempFileID) {
            files.add(file);
            tempFileID = file["projectFileId"];
          }
        });
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                  I18n.format("edit.instance.mods.download.select.version")),
              content: SizedBox(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width / 3,
                  child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder:
                          (BuildContext fileBuildContext, int fileIndex) {
                        return FutureBuilder(
                            future: CurseForgeHandler.getFileInfo(
                                curseID, files[fileIndex]["projectFileId"]),
                            builder: (context, AsyncSnapshot snapshot) {
                              if (snapshot.hasData &&
                                  (versionItem ==
                                          I18n.format('modpack.all_version')
                                      ? false
                                      : !(snapshot.data["gameVersion"].any(
                                          (version) =>
                                              version == versionItem)))) {
                                return Container();
                              } else if (snapshot.hasData) {
                                Map fileInfo = snapshot.data;
                                return ListTile(
                                  title: Text(fileInfo["displayName"]
                                      .replaceAll(".zip", "")),
                                  subtitle: CurseForgeHandler.parseReleaseType(
                                      fileInfo["releaseType"]),
                                  onTap: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) => Task(fileInfo,
                                          data["attachments"][0]["url"]),
                                    );
                                  },
                                );
                              } else {
                                return RWLLoading();
                              }
                            });
                      })),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.close_sharp),
                  tooltip: I18n.format("gui.close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CurseForgeModPack extends StatefulWidget {
  @override
  _CurseForgeModPackState createState() => _CurseForgeModPackState();
}

class Task extends StatefulWidget {
  final Map fileInfo;
  final String modPackIconUrl;

  const Task(this.fileInfo, this.modPackIconUrl);

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late File modPackFile;
  @override
  void initState() {
    super.initState();
    modPackFile = File(
        join(Directory.systemTemp.absolute.path, widget.fileInfo["fileName"]));
    thread(widget.fileInfo["downloadUrl"]);
  }

  static double _progress = 0;

  thread(url) async {
    ReceivePort port = ReceivePort();
    await Isolate.spawn(downloading, [url, modPackFile, port.sendPort]);
    port.listen((message) {
      setState(() {
        _progress = message;
      });
    });
  }

  static downloading(List args) async {
    String url = args[0];
    File packFile = args[1];
    SendPort port = args[2];
    await RPMHttpClient().download(url, packFile.path,
        onReceiveProgress: (rec, total) {
      port.send(rec / total);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0) {
      return CurseModPackHandler.setup(modPackFile, widget.modPackIconUrl);
    } else {
      return AlertDialog(
        title: Text(I18n.format('modpack.downloading')),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${(_progress * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}

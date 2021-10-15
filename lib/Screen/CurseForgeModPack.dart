import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart';

class CurseForgeModPack_ extends State<CurseForgeModPack> {
  late List BeforeList = [];
  late int Index = 0;

  TextEditingController SearchController = TextEditingController();
  ScrollController ModPackScrollController = ScrollController();

  List<String> SortItems = [
    i18n.format("edit.instance.mods.sort.curseforge.featured"),
    i18n.format("edit.instance.mods.sort.curseforge.popularity"),
    i18n.format("edit.instance.mods.sort.curseforge.update"),
    i18n.format("edit.instance.mods.sort.curseforge.name"),
    i18n.format("edit.instance.mods.sort.curseforge.author"),
    i18n.format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String SortItem =
      i18n.format("edit.instance.mods.sort.curseforge.popularity");

  List<String> VersionItems = [];
  String VersionItem = i18n.format('modpack.all_version');

  @override
  void initState() {
    ModPackScrollController.addListener(() {
      if (ModPackScrollController.position.maxScrollExtent ==
          ModPackScrollController.position.pixels) {
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
          Text(i18n.format('modpack.curseforge.title'),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.format('modpack.search')),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText: i18n.format('modpack.search.hint'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue, width: 3.0),
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
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
                    Index = 0;
                    BeforeList = [];
                  });
                },
                child: Text(i18n.format("gui.search")),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i18n.format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: SortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        SortItem = newValue!;
                        Index = 0;
                        BeforeList = [];
                      });
                    },
                    items:
                        SortItems.map<DropdownMenuItem<String>>((String value) {
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
                  Text(i18n.format("game.version")),
                  FutureBuilder(
                      future: CurseForgeHandler.getMCVersionList(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          VersionItems = [i18n.format('modpack.all_version')];
                          VersionItems.addAll(snapshot.data);

                          return DropdownButton<String>(
                            value: VersionItem,
                            onChanged: (String? newValue) {
                              setState(() {
                                VersionItem = newValue!;
                                Index = 0;
                                BeforeList = [];
                              });
                            },
                            items: VersionItems.map<DropdownMenuItem<String>>(
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
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: CurseForgeHandler.getModPackList(
                VersionItem,
                SearchController,
                BeforeList,
                Index,
                SortItems.indexOf(SortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.isEmpty) {
                  return Text(i18n.format('modpack.found'),
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                BeforeList = snapshot.data;
                Index++;
                return ListView.builder(
                  controller: ModPackScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String ModName = data["name"];
                    String ModDescription = data["summary"];
                    int CurseID = data["id"];
                    String PageUrl = data["websiteUrl"];

                    return ListTile(
                      leading: Image.network(
                        data["attachments"][0]["url"],
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded
                                        .toInt() /
                                    loadingProgress.expectedTotalBytes!.toInt()
                                : null,
                          );
                        },
                      ),
                      title: Text(ModName),
                      subtitle: Text(ModDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              utility.OpenUrl(PageUrl);
                            },
                            icon: Icon(Icons.open_in_browser),
                            tooltip:
                                i18n.format("edit.instance.mods.page.open"),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            child: Text(i18n.format("gui.install")),
                            onPressed: () {
                              List Files = [];
                              late int TempFileID = 0;
                              data["gameVersionLatestFiles"].forEach((file) {
                                //過濾相同檔案ID
                                if (file["projectFileId"] != TempFileID) {
                                  Files.add(file);
                                  TempFileID = file["projectFileId"];
                                }
                              });
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(i18n.format(
                                        "edit.instance.mods.download.select.version")),
                                    content: SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        child: ListView.builder(
                                            itemCount: Files.length,
                                            itemBuilder:
                                                (BuildContext FileBuildContext,
                                                    int FileIndex) {
                                              return FutureBuilder(
                                                  future: CurseForgeHandler
                                                      .getFileInfo(
                                                          CurseID,
                                                          Files[FileIndex][
                                                              "projectFileId"]),
                                                  builder: (context,
                                                      AsyncSnapshot snapshot) {
                                                    if (snapshot.hasData &&
                                                        (VersionItem ==
                                                                i18n.format(
                                                                    'modpack.all_version')
                                                            ? false
                                                            : !(snapshot.data[
                                                                    "gameVersion"]
                                                                .any((version) =>
                                                                    version ==
                                                                    VersionItem)))) {
                                                      return Container();
                                                    } else if (snapshot
                                                        .hasData) {
                                                      Map FileInfo =
                                                          snapshot.data;
                                                      return ListTile(
                                                        title: Text(FileInfo[
                                                                "displayName"]
                                                            .replaceAll(
                                                                ".zip", "")),
                                                        subtitle: CurseForgeHandler
                                                            .ParseReleaseType(
                                                                FileInfo[
                                                                    "releaseType"]),
                                                        onTap: () {
                                                          showDialog(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (context) =>
                                                                Task(
                                                                    FileInfo,
                                                                    data["attachments"]
                                                                            [0][
                                                                        "url"]),
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
                                        tooltip: i18n.format("gui.close"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  "${i18n.format('modpack.name')}: $ModName"),
                              content: Text(
                                  "${i18n.format('modpack.description')}: $ModDescription"),
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
          tooltip: i18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class CurseForgeModPack extends StatefulWidget {
  @override
  CurseForgeModPack_ createState() => CurseForgeModPack_();
}

class Task extends StatefulWidget {
  late var FileInfo;
  late var ModPackIconUrl;

  Task(FileInfo, ModPackIconUrl) {
    FileInfo = FileInfo;
    ModPackIconUrl = ModPackIconUrl;
  }

  @override
  Task_ createState() => Task_();
}

class Task_ extends State<Task> {
  late File ModPackFile;
  @override
  void initState() {
    super.initState();
    ModPackFile = File(
        join(Directory.systemTemp.absolute.path, widget.FileInfo["fileName"]));
    Thread(widget.FileInfo["downloadUrl"]);
  }

  static double _progress = 0;
  static int downloadedLength = 0;
  static int contentLength = 0;

  Thread(url) async {
    ReceivePort port = ReceivePort();
    await Isolate.spawn(Downloading, [url, ModPackFile, port.sendPort]);
    port.listen((message) {
      setState(() {
        _progress = message;
      });
    });
  }

  static Downloading(List args) async {
    String url = args[0];
    File PackFile = args[1];
    SendPort port = args[2];
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    contentLength += response.contentLength!;
    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloadedLength += newBytes.length;
        port.send((downloadedLength / contentLength) == 1.0
            ? 0.99
            : downloadedLength / contentLength);
      },
      onDone: () async {
        await PackFile.writeAsBytes(bytes);
        port.send(1.0);
      },
      onError: (e) {
        logger.send(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0) {
      return CurseModPackHandler.Setup(ModPackFile, widget.ModPackIconUrl);
    } else {
      return AlertDialog(
        title: Text(i18n.format('modpack.downloading')),
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

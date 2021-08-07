import 'dart:io';

import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Mod/CurseForgeHandler.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class CurseForgeMod_ extends State<CurseForgeMod> {
  late String InstanceDirName;
  TextEditingController SearchController = TextEditingController();
  late Directory ModDir =
      InstanceRepository.getInstanceModRootDir(InstanceDirName);
  late Map InstanceConfig =
      InstanceRepository.getInstanceConfig(InstanceDirName);

  late List BeforeModList = [];
  late int Index = 0;

  ScrollController ModScrollController = ScrollController();

  CurseForgeMod_(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  void initState() {
    ModScrollController.addListener(() {
      if (ModScrollController.position.maxScrollExtent ==
          ModScrollController.position.pixels) {
        //如果滑動到底部
        setState(() {});
      }
    });
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(i18n.Format("edit.instance.mods.download.curseforge"),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.Format("edit.instance.mods.download.search")),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText:
                      i18n.Format("edit.instance.mods.download.search.hint"),
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
                style: new ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {
                    Index = 0;
                    BeforeModList = [];
                  });
                },
                child: Text(i18n.Format("gui.search")),
              ),
            ],
          )
        ],
      ),
      content: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: CurseForgeHandler.getModList(
                InstanceConfig["version"],
                InstanceConfig["loader"],
                SearchController,
                BeforeModList,
                Index),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                BeforeModList = snapshot.data;
                Index++;
                return ListView.builder(
                  controller: ModScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String ModName = data["name"];
                    String ModDescription = data["summary"];
                    int CurseID = data["id"];

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
                      trailing: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              List Files = [];
                              late int TempFileID = 0;
                              data["gameVersionLatestFiles"].forEach((file) {
                                //過濾相同檔案ID
                                if (file["projectFileId"] != TempFileID) {
                                  Files.add(file);
                                  TempFileID = file["projectFileId"];
                                }
                              });
                              return AlertDialog(
                                title: Text(i18n.Format(
                                    "edit.instance.mods.download.select.version")),
                                content: Container(
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: ListView.builder(
                                        itemCount: Files.length,
                                        itemBuilder:
                                            (BuildContext FileBuildContext,
                                                int FileIndex) {
                                          return FutureBuilder(
                                              future:
                                                  CurseForgeHandler.getFileInfo(
                                                      CurseID,
                                                      InstanceConfig["version"],
                                                      InstanceConfig["loader"],
                                                      Files[FileIndex]
                                                          ["modLoader"],
                                                      Files[FileIndex]
                                                          ["projectFileId"]),
                                              builder: (context,
                                                  AsyncSnapshot snapshot) {
                                                if (snapshot.data == null) {
                                                  return Container();
                                                } else if (snapshot.hasData) {
                                                  Map FileInfo = snapshot.data;
                                                  return ListTile(
                                                    title: Text(
                                                        FileInfo["displayName"]
                                                            .replaceAll(
                                                                ".jar", "")),
                                                    subtitle: CurseForgeHandler
                                                        .ParseReleaseType(
                                                            FileInfo[
                                                                "releaseType"]),
                                                    onTap: () {
                                                      File ModFile = File(join(
                                                          ModDir.absolute.path,
                                                          FileInfo[
                                                              "fileName"]));

                                                      final url = FileInfo[
                                                          "downloadUrl"];
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            Task(url, ModFile,
                                                                ModName),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircularProgressIndicator()
                                                    ],
                                                  );
                                                }
                                              });
                                        })),
                                actions: <Widget>[
                                  IconButton(
                                    icon: Icon(Icons.close_sharp),
                                    tooltip: i18n.Format("gui.close"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text(i18n.Format("gui.install")),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  i18n.Format("edit.instance.mods.list.name") +
                                      ModName),
                              content: Text(i18n.Format(
                                      "edit.instance.mods.list.description") +
                                  ModDescription),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: i18n.Format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class CurseForgeMod extends StatefulWidget {
  late String InstanceDirName;

  CurseForgeMod(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  CurseForgeMod_ createState() => CurseForgeMod_(InstanceDirName);
}

class Task extends StatefulWidget {
  late var url;
  late var ModFile;
  late var ModName;

  Task(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  Task_ createState() => Task_(url, ModFile, ModName);
}

class Task_ extends State<Task> {
  late var url;
  late var ModFile;
  late var ModName;

  Task_(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  void initState() {
    super.initState();
    Downloading(url, ModFile);
  }

  double _progress = 0;

  Downloading(url, ModFile) async {
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    final contentLength = response.contentLength;
    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        setState(() {
          _progress = downloadedLength / contentLength!;
        });
      },
      onDone: () async {
        _progress = 1;
        await ModFile.writeAsBytes(bytes);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1) {
      return AlertDialog(
        title: Text(i18n.Format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(i18n.Format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text("${i18n.Format("gui.download.ing")} ${ModName}"),
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

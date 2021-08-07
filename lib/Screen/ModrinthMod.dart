import 'dart:io';

import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Mod/ModrinthHandler.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class ModrinthMod_ extends State<ModrinthMod> {
  late String InstanceDirName;
  TextEditingController SearchController = TextEditingController();
  late Directory ModDir =
      InstanceRepository.getInstanceModRootDir(InstanceDirName);
  late Map InstanceConfig =
      InstanceRepository.getInstanceConfig(InstanceDirName);

  ModrinthMod_(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text("ModrinthMod 模組下載頁面", textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("搜尋模組"),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText: "請輸入模組名稱來搜尋",
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
                  setState(() {});
                },
                child: Text("搜尋"),
              ),
            ],
          )
        ],
      ),
      content: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: ModrinthHandler.getModList(InstanceConfig["version"],
                InstanceConfig["loader"], SearchController),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String ModName = data["title"];
                    String ModDescription = data["description"];
                    String ModrinthID = data["mod_id"].split("local-").join("");

                    return ListTile(
                      leading: Image.network(
                        data["icon_url"],
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
                              return AlertDialog(
                                title: Text("請點選要下載的版本"),
                                content: Container(
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: FutureBuilder(
                                        future: ModrinthHandler.getModFilesInfo(
                                            ModrinthID,
                                            InstanceConfig["version"],
                                            InstanceConfig["loader"]),
                                        builder:
                                            (context, AsyncSnapshot snapshot) {
                                          if (snapshot.hasData) {
                                            return ListView.builder(
                                                itemCount:
                                                    snapshot.data!.length,
                                                itemBuilder: (BuildContext
                                                        FileBuildContext,
                                                    int VersionIndex) {
                                                  Map VersionInfo = snapshot
                                                      .data[VersionIndex];
                                                  return ListTile(
                                                    title: Text(
                                                        VersionInfo["name"]),
                                                    subtitle: ModrinthHandler
                                                        .ParseReleaseType(
                                                            VersionInfo[
                                                                "version_type"]),
                                                    onTap: () {
                                                      File ModFile = File(join(
                                                          ModDir.absolute.path,
                                                          VersionInfo["files"]
                                                              [0]["filename"]));

                                                      final url =
                                                          VersionInfo["files"]
                                                              [0]["url"];
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            Task(url, ModFile,
                                                                ModName),
                                                      );
                                                    },
                                                  );
                                                });
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                "發生未知錯誤，錯誤原因: ${snapshot.error.toString()}，如還是出現此錯誤，請至RPMLauncher官方Discord回報此問題。");
                                          } else {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator()
                                              ],
                                            );
                                          }
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
                          // print(ModrinthHandler.getFileInfo());
                        },
                        child: Text("安裝"),
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
              } else if (snapshot.hasError) {
                return Text(
                    "發生未知錯誤，錯誤原因: ${snapshot.error.toString()}，如還是出現此錯誤，請至RPMLauncher官方Discord回報此問題。");
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

class ModrinthMod extends StatefulWidget {
  late String InstanceDirName;

  ModrinthMod(InstanceDirName_) {
    InstanceDirName = InstanceDirName_;
  }

  @override
  ModrinthMod_ createState() => ModrinthMod_(InstanceDirName);
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
        title: Text("下載完成"),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("關閉"))
        ],
      );
    } else {
      return AlertDialog(
        title: Text("正在下載 ${ModName} 模組中..."),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("下載進度: ${(_progress * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}

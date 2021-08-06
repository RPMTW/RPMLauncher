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

  CurseForgeMod_(InstanceDirName_) {
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
          Text("CurseForge 模組下載頁面", textAlign: TextAlign.center),
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
            future: CurseForgeHandler.getModList(InstanceConfig["version"],
                InstanceConfig["loader"], SearchController),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
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
                              return AlertDialog(
                                title: Text("請點選要下載的版本"),
                                content: Container(
                                    height:
                                        MediaQuery.of(context).size.height / 3,
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: ListView.builder(
                                        itemCount:
                                            data["gameVersionLatestFiles"]
                                                .length,
                                        itemBuilder:
                                            (BuildContext FileBuildContext,
                                                int FileIndex) {
                                          return FutureBuilder(
                                              future: CurseForgeHandler.getFileInfo(
                                                  CurseID,
                                                  InstanceConfig["version"],
                                                  InstanceConfig["loader"],
                                                  data["gameVersionLatestFiles"]
                                                      [FileIndex]["modLoader"],
                                                  data["gameVersionLatestFiles"]
                                                          [FileIndex]
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
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      "發生未知錯誤，錯誤原因: ${snapshot.error.toString()}，如還是出現此錯誤，請至RPMLauncher官方Discord回報此問題。");
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
                          // print(CurseForgeHandler.getFileInfo());
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

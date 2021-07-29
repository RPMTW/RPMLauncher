import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import '../path.dart';

var httpClient = new HttpClient();

Future VanillaVersion() async {
  final url = Uri.parse(
      'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json');
  Response response = await get(url);
  Map<String, dynamic> body = jsonDecode(response.body);
  return body;
}

// ignore: must_be_immutable, camel_case_types
class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  late double _DownloadProgress;
  late Future vanilla_choose;
  num _DownloadDoneFileLength = 0;
  num _DownloadTotalFileLength = 0;
  var _startTime = 0;
  num _RemainingTime = 0;
  bool ShowSnapshot = false;
  bool ShowAlpha = false;
  bool ShowBeta = false;
  int choose_index = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  late List<Widget> _widgetOptions;
  static Directory LauncherFolder = dataHome;
  Directory InstanceDir =
      Directory(join(LauncherFolder.absolute.path, "instances"));

  void initState() {
    super.initState();
    _DownloadProgress = 0.0;
    vanilla_choose = VanillaVersion();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void ChangeProgress(setState_) {
    setState_(() {
      _DownloadProgress = _DownloadDoneFileLength / _DownloadTotalFileLength;
      int elapsedTime = DateTime.now().millisecondsSinceEpoch - _startTime;
      num allTimeForDownloading =
          elapsedTime * _DownloadTotalFileLength / _DownloadDoneFileLength;
      if (allTimeForDownloading.isNaN || allTimeForDownloading.isInfinite)
        allTimeForDownloading = 0;
      int time = allTimeForDownloading.toInt() - elapsedTime;
      _RemainingTime = DateTime.fromMillisecondsSinceEpoch(time).minute;
    });
  }

  var name_controller = TextEditingController();

  Future<void> DownloadFile(
      String url, String filename, String path, setState_, fileSha1) async {
    var dir_ = path;
    File file =
        await File(join(dataHome.absolute.path, "libraries", dir_, filename))
          ..createSync(recursive: true);
    if (sha1.convert(file.readAsBytesSync()).toString() ==
        fileSha1.toString()) {
      _DownloadDoneFileLength = _DownloadDoneFileLength + 1;
      ChangeProgress(setState_);
      return;
    }
    await http.get(Uri.parse(url)).then((response) async {
      await file.writeAsBytes(response.bodyBytes);
    });
    if (filename.contains("natives-${Platform.operatingSystem}")) {
      //如果是natives
      final bytes = await file.readAsBytesSync();
      final archive = await ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final ZipFileName = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          await File(join(dir_, ZipFileName))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          await Directory(join(dir_, ZipFileName))
            ..create(recursive: true);
        }
      }
      file.delete(recursive: true);
    }
    _DownloadDoneFileLength = _DownloadDoneFileLength + 1; //Done Download
    ChangeProgress(setState_);
  }

  Future DownloadNatives(i, body, version, setState_) async {
    if (i["downloads"]["classifiers"]
        .keys
        .contains("natives-${Platform.operatingSystem}")) {
      List split_ = i["downloads"]["classifiers"]
              ["natives-${Platform.operatingSystem}"]["path"]
          .toString()
          .split("/");
      DownloadFile(
          i["downloads"]["classifiers"]["natives-${Platform.operatingSystem}"]
              ["url"],
          split_[split_.length - 1],
          join(dataHome.absolute.path, "versions", version, "natives"),
          setState_,
          i["downloads"]["classifiers"]["natives-${Platform.operatingSystem}"]
              ["sha1"]);
    }
  }

  Future DownloadGame(setState_, data_url, version) async {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse(data_url);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    DownloadFile(
        //Download Client File
        body["downloads"]["client"]["url"],
        "client.jar",
        join(dataHome.absolute.path, "versions", version),
        setState_,
        body["downloads"]["client"]["sha1"]);
    File(join(InstanceDir.absolute.path, name_controller.text, "args.json"))
        .writeAsStringSync(json.encode(body["arguments"]));
    DownloadLib(body, version, setState_);
    DownloadAssets(body, setState_, version);
  }

  Future DownloadAssets(data, setState_, version) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    _DownloadTotalFileLength =
        _DownloadTotalFileLength + body["objects"].keys.length;
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${version}.json"))
      ..createSync(recursive: true);
    IndexFile.writeAsStringSync(body.toString());
    for (var i in body["objects"].keys) {
      var hash = body["objects"][i]["hash"].toString();
      await DownloadFile(
              "https://resources.download.minecraft.net/${hash.substring(0, 2)}/${hash}",
              hash,
              join(dataHome.absolute.path, "assets", "objects",
                  hash.substring(0, 2)),
              setState_,
              hash)
          .timeout(new Duration(milliseconds: 180), onTimeout: () {});
    }
  }

  Future DownloadLib(body, version, setState_) async {
    _DownloadTotalFileLength =
        _DownloadTotalFileLength + body["libraries"].length;
    for (var i in body["libraries"]) {
      if (i["downloads"].keys.contains("classifiers")) {
        DownloadNatives(i, body, version, setState_);
      } else if (i["downloads"].keys.contains("artifact")) {
        List split_ = i["downloads"]["artifact"]["path"].toString().split("/");
        DownloadFile(
            i["downloads"]["artifact"]["url"],
            split_[split_.length - 1],
            split_.sublist(0, split_.length - 2).join("/"),
            setState_,
            i["downloads"]["artifact"]["sha1"]);
      }
    }
  }

  late var border_colour = Colors.lightBlue;

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      FutureBuilder(
          future: vanilla_choose,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ListView.builder(
                  itemCount: snapshot.data["versions"].length,
                  itemBuilder: (context, index) {
                    var list_tile = ListTile(
                      title: Text(
                          snapshot.data["versions"][index]["id"].toString()),
                      tileColor: choose_index == index
                          ? Colors.white30
                          : Colors.white10,
                      onTap: () {
                        choose_index = index;
                        String data_id =
                            snapshot.data["versions"][choose_index]["id"];
                        String data_url =
                            snapshot.data["versions"][choose_index]["url"];
                        name_controller.text =
                            snapshot.data["versions"][index]["id"].toString();
                        setState(() {});
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              if (File(join(InstanceDir.absolute.path,
                                      name_controller.text, "instance.cfg"))
                                  .existsSync()) {
                                border_colour = Colors.red;
                              }
                              return AlertDialog(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text("建立安裝檔"),
                                content: Row(
                                  children: [
                                    Text("安裝檔名稱: "),
                                    Expanded(
                                        child: TextField(
                                            decoration: InputDecoration(
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: border_colour,
                                                    width: 5.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: border_colour,
                                                    width: 3.0),
                                              ),
                                            ),
                                            controller: name_controller)),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('取消'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('確定'),
                                    onPressed: () async {
                                      if (name_controller.text != "" &&
                                          !File(join(
                                                  InstanceDir.absolute.path,
                                                  name_controller.text,
                                                  "instance.cfg"))
                                              .existsSync()) {
                                        border_colour = Colors.lightBlue;
                                        ;
                                        var new_ = true;
                                        File(join(
                                            InstanceDir.absolute.path,
                                            name_controller.text,
                                            "instance.cfg"))
                                          ..createSync(recursive: true)
                                          ..writeAsStringSync("name=" +
                                              name_controller.text +
                                              "\n" +
                                              "version=" +
                                              snapshot.data["versions"][index]
                                                      ["id"]
                                                  .toString());
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) => MyApp()),
                                        );
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                  builder: (context, setState) {
                                                if (new_ == true) {
                                                  DownloadGame(
                                                      setState,
                                                      data_url,
                                                      snapshot.data["versions"]
                                                              [index]["id"]
                                                          .toString());
                                                  new_ = false;
                                                }
                                                if (_DownloadProgress == 1) {
                                                  return AlertDialog(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    title: Text("下載完成"),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Text("關閉"))
                                                    ],
                                                  );
                                                } else {
                                                  return WillPopScope(
                                                    onWillPop: () =>
                                                        Future.value(false),
                                                    child: AlertDialog(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      title: Text(
                                                          "下載遊戲資料中...\n尚未下載完成，請勿關閉此視窗"),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          LinearProgressIndicator(
                                                            value:
                                                                _DownloadProgress,
                                                          ),
                                                          Text(
                                                              "${(_DownloadProgress * 100).toStringAsFixed(2)}%"),
                                                          Text(
                                                              "預計剩餘時間: ${_RemainingTime} 分鐘"),
                                                        ],
                                                      ),
                                                      actions: <Widget>[],
                                                    ),
                                                  );
                                                }
                                              });
                                            });
                                      } else {
                                        border_colour = Colors.red;
                                      }
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                    );
                    if (ShowAlpha && ShowSnapshot && ShowBeta) {
                      return list_tile;
                    } else if (ShowAlpha && ShowSnapshot) {
                      if (snapshot.data["versions"][index]["type"] !=
                          "old_beta") {
                        return list_tile;
                      }
                    } else if (ShowAlpha && ShowBeta) {
                      if (snapshot.data["versions"][index]["type"] !=
                          "snapshot") {
                        return list_tile;
                      }
                    } else if (ShowBeta && ShowSnapshot) {
                      if (snapshot.data["versions"][index]["type"] !=
                          "old_alpha") {
                        return list_tile;
                      }
                    } else if (ShowAlpha) {
                      if (snapshot.data["versions"][index]["type"] !=
                              "snapshot" &&
                          snapshot.data["versions"][index]["type"] !=
                              "old_beta") {
                        return list_tile;
                      }
                    } else if (ShowSnapshot) {
                      if (snapshot.data["versions"][index]["type"] !=
                              "old_alpha" &&
                          snapshot.data["versions"][index]["type"] !=
                              "old_beta") {
                        return list_tile;
                      }
                    } else if (ShowBeta) {
                      if (snapshot.data["versions"][index]["type"] !=
                              "old_alpha" &&
                          snapshot.data["versions"][index]["type"] !=
                              "snapshot") {
                        return list_tile;
                      }
                    } else {
                      if (snapshot.data["versions"][index]["type"] !=
                              "snapshot" &&
                          snapshot.data["versions"][index]["type"] !=
                              "old_alpha" &&
                          snapshot.data["versions"][index]["type"] !=
                              "old_beta") {
                        return list_tile;
                      }
                    }

                    return Container();
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
      Text(
        '壓縮檔',
        style: optionStyle,
        textAlign: TextAlign.center,
      ),
      Text(
        '鍛造',
        style: optionStyle,
        textAlign: TextAlign.center,
      ),
      Text(
        '織物',
        style: optionStyle,
        textAlign: TextAlign.center,
      ),
    ];
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("請選擇安裝檔的類型"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new MyApp()),
            );
          },
        ),
      ),
      body: SplitView(
        view1: _widgetOptions.elementAt(_selectedIndex),
        view2: Column(
          children: [
            Text("版本過濾器"),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowSnapshot = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowSnapshot,
              ),
              title: Text("顯示快照版本"),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowAlpha = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowAlpha,
              ),
              title: Text("顯示alpha版本"),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowBeta = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowBeta,
              ),
              title: Text("顯示beta版本"),
            ),
          ],
        ),
        gripSize: 0,
        initialWeight: 0.83,
        viewMode: SplitViewMode.Horizontal,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Vanilla.ico")),
              label: '原版',
              tooltip: '原版'),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.folder_open_outlined)),
              label: '壓縮檔',
              tooltip: '壓縮檔'),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Forge.jpg")),
              label: 'Forge',
              tooltip: 'Forge'),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Fabric.png")),
              label: 'Fabric',
              tooltip: 'Fabric'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }
}

class VersionSelection extends StatefulWidget {
  @override
  VersionSelection_ createState() => VersionSelection_();
}

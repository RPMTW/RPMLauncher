import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:split_view/split_view.dart';
import '../path.dart';

import '../main.dart';

Future VanillaVersion() async {
  final url = Uri.parse(
      'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json');
  Response response = await get(url);
  Map<String, dynamic> body = jsonDecode(response.body);
  return body;
}

Future DownloadLink(url_input) async {
  final url = Uri.parse(url_input);
  Response response = await get(url);
  Map<String, dynamic> body = jsonDecode(response.body);
  return body["downloads"]["client"]["url"];
}

// ignore: must_be_immutable, camel_case_types
class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  late Future vanilla_choose;
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
      Directory(join(LauncherFolder.absolute.path, "RPMLauncher", "instance"));

  void initState() {
    super.initState();
    vanilla_choose = VanillaVersion();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static var httpClient = new HttpClient();

  Future DownloadFile(String url, String filename, String path) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir_ = path;
    File file = new File(join(dir_, filename))..create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  var name_controller = TextEditingController();

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
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text("建立安裝檔"),
                                content: Row(
                                  children: [
                                    Text("安裝檔名稱: "),
                                    Expanded(
                                        child: TextField(
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
                                    child: const Text('確認'),
                                    onPressed: () async {
                                      if (name_controller.text != "") {
                                        DownloadFile(
                                            await DownloadLink(data_url),
                                            "client.jar",
                                            join(InstanceDir.absolute.path,
                                                name_controller.text));
                                        File(join(InstanceDir.absolute.path,
                                            name_controller.text,"instance.cfg"))..createSync(recursive: true)..writeAsStringSync("name="+name_controller.text);
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (context) => MyApp()),
                                        );
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
  late double _DownloadProgress2;
  late Future vanilla_choose;
  late String _DownloadFileName;
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
      Directory(join(LauncherFolder.absolute.path, "RPMLauncher", "instances"));

  void initState() {
    super.initState();
    _DownloadProgress = 0.0;
    _DownloadProgress2 = 0.0;
    vanilla_choose = VanillaVersion();
    _DownloadFileName = "";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  var name_controller = TextEditingController();

  Future<void> DownloadFile(
      String url, String filename, String path, setState_,[now=1.0]) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    String dir_ = path;
    File file = File(join(
        dataHome.absolute.path, "RPMLauncher", "libraries", dir_, filename))
      ..createSync(recursive: true);
    var length = response.contentLength;
    var sink = file.openWrite();
    Future.doWhile(() async {
      var received = await file.length();
      setState_(() {
        _DownloadProgress2 = received / length;
        _DownloadFileName =filename;
        _DownloadProgress =now;
      });
      return received != length;
    });
    await response.pipe(sink);
  }
  Future DownloadJAR(url_input,setState_) async {
    final url = Uri.parse(url_input);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    return body["downloads"]["client"]["url"];
  }
  Future DownloadLink(url_input, setState_) async {
    final url = Uri.parse(url_input);
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    await DownloadFile(await DownloadJAR(url_input,setState_), "client.jar",
        join(InstanceDir.absolute.path, name_controller.text), setState_,1/(body["libraries"].length-1));
    File(join(InstanceDir.absolute.path, name_controller.text,"args.json")).writeAsStringSync(json.encode(body["arguments"]));
    for (var i in body["libraries"]) {
      if (i["downloads"].keys.contains("artifact")){
      List split_ = i["downloads"]["artifact"]["path"].toString().split("/");
      await DownloadFile(i["downloads"]["artifact"]["url"], split_[split_.length - 1],
          split_.sublist(0, split_.length - 2).join("/"), setState_,(body["libraries"].indexOf(i)+1)/(body["libraries"].length));
        
      }else if(i["downloads"].keys.contains("classifiers")){
        if (i["downloads"]["classifiers"].keys.contains("natives-linux")&&Platform.isLinux){
          List split_ = i["downloads"]["classifiers"]["natives-linux"]["path"].toString().split("/");
          await DownloadFile(i["downloads"]["classifiers"]["natives-linux"]["url"], split_[split_.length - 1],
              split_.sublist(0, split_.length - 2).join("/"), setState_,(body["libraries"].indexOf(i)+1)/(body["libraries"].length));
        }else if(i["downloads"]["classifiers"].keys.contains("natives-osx")&&Platform.isMacOS){
          List split_ = i["downloads"]["classifiers"]["natives-osx"]["path"].toString().split("/");
          await DownloadFile(i["downloads"]["classifiers"]["natives-osx"]["url"], split_[split_.length - 1],
              split_.sublist(0, split_.length - 2).join("/"), setState_,(body["libraries"].indexOf(i)+1)/(body["libraries"].length));
        }else if(i["downloads"]["classifiers"].keys.contains("natives-windows")&&Platform.isWindows){
          List split_ = i["downloads"]["classifiers"]["natives-windows"]["path"].toString().split("/");
          await DownloadFile(i["downloads"]["classifiers"]["natives-windows"]["url"], split_[split_.length - 1],
              split_.sublist(0, split_.length - 2).join("/"), setState_,(body["libraries"].indexOf(i)+1)/(body["libraries"].length));
        }

      }
    }

  }

  Future DownloadLib(setState_, data_url) async {
    await DownloadLink(data_url, setState_);
  }
  late var border_colour=Colors.lightBlue;
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
                              if(File(join(
                                  InstanceDir.absolute.path,
                                  name_controller.text,
                                  "instance.cfg")).existsSync()){
                                border_colour=Colors.red;
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
                                                borderSide: BorderSide(color: border_colour, width: 5.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: border_colour, width: 3.0),
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
                                      if (name_controller.text != ""&&!File(join(
                                          InstanceDir.absolute.path,
                                          name_controller.text,
                                          "instance.cfg")).existsSync()) {
                                        border_colour=Colors.lightBlue;;
                                        var new_ = true;
                                        File(join(
                                            InstanceDir.absolute.path,
                                            name_controller.text,
                                            "instance.cfg"))
                                          ..createSync(recursive: true)
                                          ..writeAsStringSync(
                                              "name=" + name_controller.text+"\n"+"version="+snapshot.data["versions"][index]["id"].toString());
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
                                                  DownloadLib(
                                                      setState, data_url);
                                                  new_ = false;
                                                }
                                                if (_DownloadProgress == 1) {
                                                  return AlertDialog(
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    title: Text("下載資源檔案中..."),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text("  " +
                                                            _DownloadFileName),
                                                        LinearProgressIndicator(
                                                          value:
                                                              _DownloadProgress,
                                                        ),
                                                      ],
                                                    ),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Text("Finish"))
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
                                                      title: Text("下載資源檔案中..."),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text("  " +
                                                              _DownloadFileName),
                                                          LinearProgressIndicator(
                                                            value:
                                                                _DownloadProgress,
                                                          ),
                                                          SizedBox(height: 10,),
                                                          LinearProgressIndicator(
                                                            value:
                                                            _DownloadProgress2,
                                                          ),
                                                        ],
                                                      ),
                                                      actions: <Widget>[],
                                                    ),
                                                  );
                                                }
                                              });
                                            });
                                      }else{
                                        border_colour=Colors.red;
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

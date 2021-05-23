import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';

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
  late Future vanilla_choose;
  bool ShowSnapshot = false;
  bool ShowAlpha = false;
  int choose_index = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  late List<Widget> _widgetOptions;

  void initState() {
    super.initState();
    vanilla_choose = VanillaVersion();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                  if (ShowSnapshot == true) {
                    if (snapshot.data["versions"][index]["type"] !=
                            "old_alpha" &&
                        ShowAlpha != true) {
                      return ListTile(
                        title: Text(
                            snapshot.data["versions"][index]["id"].toString()),
                        tileColor: choose_index == index
                            ? Colors.white30
                            : Colors.white10,
                        onTap: () {
                          choose_index = index;
                          setState(() {});
                        },
                      );
                    }
                  } else if (ShowAlpha == true) {
                    if (snapshot.data["versions"][index]["type"] !=
                            "snapshot" &&
                        ShowSnapshot != true) {
                      return ListTile(
                        title: Text(
                            snapshot.data["versions"][index]["id"].toString()),
                        tileColor: choose_index == index
                            ? Colors.white30
                            : Colors.white10,
                        onTap: () {
                          choose_index = index;
                          setState(() {});
                        },
                      );
                    }
                  } else {
                    if (snapshot.data["versions"][index]["type"] !=
                        "snapshot") {
                      if (snapshot.data["versions"][index]["type"] !=
                          "old_alpha") {
                        return ListTile(
                          title: Text(snapshot.data["versions"][index]["id"]
                              .toString()),
                          tileColor: choose_index == index
                              ? Colors.white30
                              : Colors.white10,
                          onTap: () {
                            choose_index = index;
                            setState(() {});
                          },
                        );
                      }
                    }
                  }
                  if (ShowSnapshot==true&&ShowAlpha==true){
                    return ListTile(
                      title: Text(snapshot.data["versions"][index]["id"]
                          .toString()),
                      tileColor: choose_index == index
                          ? Colors.white30
                          : Colors.white10,
                      onTap: () {
                        choose_index = index;
                        setState(() {});
                      },
                    );
                  }
                  return Container();
                },
              );
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
            )
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

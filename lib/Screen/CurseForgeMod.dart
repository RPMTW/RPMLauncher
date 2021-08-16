import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/CurseForgeModVersion.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  List<String> SortItems = [
    i18n.Format("edit.instance.mods.sort.curseforge.featured"),
    i18n.Format("edit.instance.mods.sort.curseforge.popularity"),
    i18n.Format("edit.instance.mods.sort.curseforge.update"),
    i18n.Format("edit.instance.mods.sort.curseforge.name"),
    i18n.Format("edit.instance.mods.sort.curseforge.author"),
    i18n.Format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String SortItem =
      i18n.Format("edit.instance.mods.sort.curseforge.popularity");

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
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i18n.Format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: SortItem,
                    style: TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      setState(() {
                        SortItem = newValue!;
                        Index = 0;
                        BeforeModList = [];
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
                Index,
                SortItems.indexOf(SortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.length == 0) {
                  return Text("目前的篩選方式找不到任何模組",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
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
                              if (await canLaunch(PageUrl)) {
                                launch(PageUrl);
                              } else {
                                print("Can't open the url $PageUrl");
                              }
                            },
                            icon: Icon(Icons.open_in_browser),
                            tooltip:
                                i18n.Format("edit.instance.mods.page.open"),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  List Files = [];
                                  late int TempFileID = 0;
                                  data["gameVersionLatestFiles"]
                                      .forEach((file) {
                                    //過濾相同檔案ID
                                    if (file["projectFileId"] != TempFileID) {
                                      Files.add(file);
                                      TempFileID = file["projectFileId"];
                                    }
                                  });
                                  return CurseForgeModVersion(
                                      Files, CurseID, ModDir, InstanceConfig);
                                },
                              );
                            },
                            child: Text(i18n.Format("gui.install")),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  i18n.Format("edit.instance.mods.list.name") +
                                      ModName,
                                  textAlign: TextAlign.center),
                              content: Text(
                                  i18n.Format(
                                          "edit.instance.mods.list.description") +
                                      ModDescription,
                                  textAlign: TextAlign.center),
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

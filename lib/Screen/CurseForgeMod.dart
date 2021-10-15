// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/CurseForgeModVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class CurseForgeMod_ extends State<CurseForgeMod> {
  TextEditingController SearchController = TextEditingController();
  Directory get ModDir =>
      InstanceRepository.getModRootDir(widget.InstanceDirName);
  late InstanceConfig instanceConfig =
      InstanceRepository.instanceConfig(widget.InstanceDirName);

  late List BeforeModList = [];
  bool isReset = true;
  int Index = 20;

  ScrollController ModScrollController = ScrollController();

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

  @override
  void initState() {
    ModScrollController.addListener(() {
      if ((ModScrollController.position.maxScrollExtent -
              ModScrollController.position.pixels) <
          50) {
        //如果快要滑動到底部
        Index = Index + 20;
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
          Text(i18n.format("edit.instance.mods.download.curseforge"),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.format("edit.instance.mods.download.search")),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText:
                      i18n.format("edit.instance.mods.download.search.hint"),
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
                    isReset = true;
                    BeforeModList = [];
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
                        isReset = true;
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
                instanceConfig.version,
                instanceConfig.loader,
                SearchController,
                BeforeModList,
                isReset ? 0 : Index,
                SortItems.indexOf(SortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                isReset = false;
                if (snapshot.data.isEmpty) {
                  return Text("目前的篩選方式找不到任何模組",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                BeforeModList = snapshot.data;
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
                                      Files: Files,
                                      CurseID: CurseID,
                                      ModDir: ModDir,
                                      instanceConfig: instanceConfig);
                                },
                              );
                            },
                            child: Text(i18n.format("gui.install")),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  i18n.format("edit.instance.mods.list.name") +
                                      ModName,
                                  textAlign: TextAlign.center),
                              content: Text(
                                  i18n.format(
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

class CurseForgeMod extends StatefulWidget {
  late String InstanceDirName;

  CurseForgeMod(_InstanceDirName) {
    InstanceDirName = _InstanceDirName;
  }

  @override
  CurseForgeMod_ createState() => CurseForgeMod_();
}

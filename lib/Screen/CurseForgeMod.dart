import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/CurseForgeModVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class _CurseForgeModState extends State<CurseForgeMod> {
  TextEditingController searchController = TextEditingController();
  Directory get modDir =>
      InstanceRepository.getModRootDir(widget.instanceDirName);
  late InstanceConfig instanceConfig =
      InstanceRepository.instanceConfig(widget.instanceDirName);

  late List beforeModList = [];
  bool isReset = true;
  int index = 20;

  ScrollController modScrollController = ScrollController();

  List<String> sortItems = [
    i18n.format("edit.instance.mods.sort.curseforge.featured"),
    i18n.format("edit.instance.mods.sort.curseforge.popularity"),
    i18n.format("edit.instance.mods.sort.curseforge.update"),
    i18n.format("edit.instance.mods.sort.curseforge.name"),
    i18n.format("edit.instance.mods.sort.curseforge.author"),
    i18n.format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String sortItem =
      i18n.format("edit.instance.mods.sort.curseforge.popularity");

  @override
  void initState() {
    modScrollController.addListener(() {
      if ((modScrollController.position.maxScrollExtent -
              modScrollController.position.pixels) <
          50) {
        //如果快要滑動到底部
        index = index + 20;
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
                controller: searchController,
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
                    beforeModList = [];
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
                    value: sortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        sortItem = newValue!;
                        isReset = true;
                        beforeModList = [];
                      });
                    },
                    items:
                        sortItems.map<DropdownMenuItem<String>>((String value) {
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
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: CurseForgeHandler.getModList(
                instanceConfig.version,
                instanceConfig.loader,
                searchController,
                beforeModList,
                isReset ? 0 : index,
                sortItems.indexOf(sortItem)),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                isReset = false;
                if (snapshot.data.isEmpty) {
                  return Text("目前的篩選方式找不到任何模組",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                beforeModList = snapshot.data;
                return ListView.builder(
                  controller: modScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String modName = data["name"];
                    String modDescription = data["summary"];
                    int curseID = data["id"];
                    String pageUrl = data["websiteUrl"];

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
                      title: Text(modName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              utility.openUrl(pageUrl);
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
                                  List files = [];
                                  int tempFileID = 0;
                                  data["gameVersionLatestFiles"]
                                      .forEach((file) {
                                    //過濾相同檔案ID
                                    if (file["projectFileId"] != tempFileID) {
                                      files.add(file);
                                      tempFileID = file["projectFileId"];
                                    }
                                  });
                                  return CurseForgeModVersion(
                                      Files: files,
                                      CurseID: curseID,
                                      ModDir: modDir,
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
                                      modName,
                                  textAlign: TextAlign.center),
                              content: Text(
                                  i18n.format(
                                          "edit.instance.mods.list.description") +
                                      modDescription,
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
  final String instanceDirName;

  const CurseForgeMod(this.instanceDirName);
  @override
  _CurseForgeModState createState() => _CurseForgeModState();
}

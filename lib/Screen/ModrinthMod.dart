import 'dart:io';

import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/ModrinthHandler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/ModrinthModVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class _ModrinthModState extends State<ModrinthMod> {
  String get instanceDirName => widget.instanceDirName;
  TextEditingController searchController = TextEditingController();
  late Directory modDir = InstanceRepository.getModRootDir(instanceDirName);
  late InstanceConfig instanceConfig =
      InstanceRepository.instanceConfig(instanceDirName);

  late List beforeModList = [];
  late int index = 0;

  List<String> sortItemsCode = ["relevance", "downloads", "updated", "newest"];
  List<String> sortItems = [
    I18n.format("edit.instance.mods.sort.modrinth.relevance"),
    I18n.format("edit.instance.mods.sort.modrinth.downloads"),
    I18n.format("edit.instance.mods.sort.modrinth.updated"),
    I18n.format("edit.instance.mods.sort.modrinth.newest")
  ];
  String sortItem = I18n.format("edit.instance.mods.sort.modrinth.relevance");

  ScrollController modScrollController = ScrollController();

  @override
  void initState() {
    modScrollController.addListener(() {
      if (modScrollController.position.maxScrollExtent ==
          modScrollController.position.pixels) {
        //如果滑動到底部
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
          Text(I18n.format("edit.instance.mods.download.modrinth"),
              textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(I18n.format("edit.instance.mods.download.search")),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: searchController,
                decoration: InputDecoration(
                  hintText:
                      I18n.format("edit.instance.mods.download.search.hint"),
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
                    index = 0;
                    beforeModList = [];
                  });
                },
                child: Text(I18n.format("gui.search")),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(I18n.format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: sortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        sortItem = newValue!;
                        index = 0;
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
            future: ModrinthHandler.getModList(
                instanceConfig.version,
                instanceConfig.loader,
                searchController,
                beforeModList,
                index,
                sortItemsCode[sortItems.indexOf(sortItem)]),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.isEmpty) {
                  return Text("目前的篩選方式找不到任何模組",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                index++;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  controller: modScrollController,
                  itemBuilder: (BuildContext context, int index) {
                    Map data = snapshot.data[index];
                    String modName = data["title"];
                    String modDescription = data["description"];
                    String modrinthID = data["mod_id"].split("local-").join("");
                    String pageUrl = data["page_url"];

                    late Widget modIcon;
                    if (data["icon_url"].isEmpty) {
                      modIcon = Icon(Icons.image, size: 50);
                    } else {
                      modIcon = Image.network(
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
                      );
                    }

                    return ListTile(
                      leading: modIcon,
                      title: Text(modName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              Uttily.openUrl(pageUrl);
                            },
                            icon: Icon(Icons.open_in_browser),
                            tooltip:
                                I18n.format("edit.instance.mods.page.open"),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return ModrinthModVersion(modrinthID,
                                      instanceConfig, modDir, modName);
                                },
                              );
                            },
                            child: Text(I18n.format("gui.install")),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                I18n.format("edit.instance.mods.list.name") +
                                    modName,
                                textAlign: TextAlign.center,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ModrinthHandler.parseSide(
                                      I18n.format("gui.side.client") + ": ",
                                      "client_side",
                                      data),
                                  ModrinthHandler.parseSide(
                                      I18n.format("gui.side.server") + ": ",
                                      "server_side",
                                      data),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                      I18n.format(
                                              "edit.instance.mods.list.description") +
                                          modDescription,
                                      textAlign: TextAlign.center)
                                ],
                              ),
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
          tooltip: I18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class ModrinthMod extends StatefulWidget {
  final String instanceDirName;

  const ModrinthMod({required this.instanceDirName});

  @override
  _ModrinthModState createState() => _ModrinthModState();
}

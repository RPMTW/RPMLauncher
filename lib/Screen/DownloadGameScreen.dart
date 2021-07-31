import 'package:flutter/material.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';

class DownloadGameScreen_ extends State<DownloadGameScreen> {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;
  late var IsFabric;
  late var IsCompatibleVersion;
  late var finish;

  DownloadGameScreen_(
      border_colour_, name_controller_, InstanceDir_, Data_, ModLoaderName_) {
    border_colour = border_colour_;
    name_controller = name_controller_;
    InstanceDir = InstanceDir_;
    Data = Data_;
    ModLoaderName = ModLoaderName_;
  }

  @override
  void initState() {
    super.initState();
    IsFabric = ModLoader()
            .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName)) ==
        ModLoader().Fabric;
  }

  Widget build(BuildContext context) {
    if (IsFabric) {
      FabricAPI().IsCompatibleVersion(Data["id"]).then((value) => setState(() {
            IsCompatibleVersion = value;
            finish = true;
            return;
          }));
      try {
        if (IsCompatibleVersion) {
          return AddInstanceWidget(
              border_colour, InstanceDir, name_controller, Data);
        } else {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text("錯誤資訊"),
            content: Text("目前選擇的Minecraft版本與選擇的模組載入器版本不相容"),
            actions: <Widget>[
              TextButton(
                child: Text("ok"),
                onPressed: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => VersionSelection()));
                },
              ),
            ],
          );
        }
      } catch (err) {}
    } else {
      return AddInstanceWidget(
          border_colour, InstanceDir, name_controller, Data);
    }
    return AlertDialog(
      title: Column(
        children:[
          Text("正在檢查遊戲版本是否符合模組載入器所需版本\n",textAlign: TextAlign.center),
          CircularProgressIndicator()
        ]),
    );
  }
}

class DownloadGameScreen extends StatefulWidget {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;

  DownloadGameScreen(
      border_colour_, name_controller_, InstanceDir_, Data_, ModLoaderName_) {
    border_colour = border_colour_;
    name_controller = name_controller_;
    InstanceDir = InstanceDir_;
    Data = Data_;
    ModLoaderName = ModLoaderName_;
  }

  @override
  DownloadGameScreen_ createState() => DownloadGameScreen_(
      border_colour, name_controller, InstanceDir, Data, ModLoaderName);
}

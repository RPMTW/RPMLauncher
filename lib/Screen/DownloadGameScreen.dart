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

  FabricIncompatibleErr(value, context) {
    if (value) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
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
      },
    );
  }

  Widget build(BuildContext context) {
    if (IsFabric) {
      FabricAPI()
          .IsCompatibleVersion(Data["id"])
          .then((value) => FabricIncompatibleErr(value, context));
    }else{
      return AddInstanceWidget(border_colour, InstanceDir, name_controller, Data);
    }
    return AddInstanceWidget(border_colour, InstanceDir, name_controller, Data);
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

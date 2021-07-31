import 'package:flutter/material.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Screen/VersionSelection.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';

class DownloadGameScreen_ extends State<DownloadGameScreen> {
  late var border_colour;
  late var name_controller;
  late var InstanceDir;
  late var Data;
  late var ModLoaderName;
  late var ModLoaderID;
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
    ModLoaderID = ModLoader()
        .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName));
  }

  Widget build(BuildContext context) {
    if (IsFabric) {
      try {
        FabricAPI().IsCompatibleVersion(Data["id"]).then((value) => setState(() {
            IsCompatibleVersion = value;
            finish = true;
            return;
          }));
        if (IsCompatibleVersion) {
          return AddInstanceWidget(
              border_colour, InstanceDir, name_controller, Data, ModLoaderID);
        } else {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(i18n().Format("gui.error.info")),
            content: Text(
                i18n().Format("version.list.mod.loader.incompatible.error")),
            actions: <Widget>[
              TextButton(
                child: Text(i18n().Format("gui.ok")),
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
          border_colour, InstanceDir, name_controller, Data, ModLoaderID);
    }
    return AlertDialog(
      title: Column(children: [
        Text("${i18n().Format("version.list.mod.loader.incompatible.check")}\n",
            textAlign: TextAlign.center),
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

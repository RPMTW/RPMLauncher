import 'package:flutter/material.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';

late var Data;
late var ModLoaderID;
late var IsFabric;
late var IsCompatibleVersion;

DownloadGameDialog(
    border_colour, name_controller, InstanceDir, Data, ModLoaderName, context) {
  IsFabric = ModLoader()
          .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName)) ==
      ModLoader().Fabric;
  ModLoaderID = ModLoader()
      .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName));
  //not the best way but at least it works
  Future.delayed(Duration(seconds: 0)).then((value) {
    if (IsFabric) {
      try {
        FabricAPI().IsCompatibleVersion(Data["id"]).then((value) {
          IsCompatibleVersion = value;
          if (IsCompatibleVersion) {
            showDialog(
              context: context,
              builder: (context) => AddInstanceDialog(border_colour,
                  InstanceDir, name_controller, Data, ModLoaderID),
            );
          } else {
            Navigator.pop(context);
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n().Format("gui.error.info")),
                    content: Text(i18n()
                        .Format("version.list.mod.loader.incompatible.error")),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n().Format("gui.ok")),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                });
          }
          return;
        }).catchError((err) {});
      } catch (err) {}
    } else {
      showDialog(
        context: context,
        builder: (context) => AddInstanceDialog(
            border_colour, InstanceDir, name_controller, Data, ModLoaderID),
      );
    }
  });
  return AlertDialog(
    title: Column(children: [CircularProgressIndicator()]),
  );
}

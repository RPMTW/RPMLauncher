import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart';

Widget DownloadGameDialog(
    borderColour, nameController, Map metaData, ModLoaders loader) {
  //not the best way but at least it works
  Future.delayed(Duration(seconds: 0)).then((value) {
    //Is Fabric Loader
    if (loader == ModLoaders.fabric) {
      try {
        FabricAPI().isCompatibleVersion(metaData["id"]).then((value) {
          if (value) {
            navigator.pop();
            showDialog(
              context: navigator.context,
              builder: (context) => FabricVersion(
                  borderColour, nameController, metaData),
            );
          } else {
            navigator.pop();
            showDialog(
                barrierDismissible: false,
                context: navigator.context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n.format("gui.error.info")),
                    content: Text(i18n
                        .format("version.list.mod.loader.incompatible.error")),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n.format("gui.ok")),
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
    } else if (loader == ModLoaders.forge) {
      //Is Forge Loader

      try {
        ForgeAPI.isCompatibleVersion(metaData["id"]).then((value) {
          if (value) {
            navigator.pop();
            showDialog(
              context: navigator.context,
              builder: (context) =>
                  ForgeVersion(borderColour, nameController, metaData),
            );
          } else {
            navigator.pop();
            showDialog(
                barrierDismissible: false,
                context: navigator.context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n.format("gui.error.info")),
                    content: Text(i18n
                        .format("version.list.mod.loader.incompatible.error")),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n.format("gui.ok")),
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
      navigator.pop();
      showDialog(
        context: navigator.context,
        builder: (context) => AddInstanceDialog(
            borderColour, nameController, metaData, loader, "null"),
      );
    }
  });
  return Center(child: RWLLoading());
}

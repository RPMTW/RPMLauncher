import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';

late var Data;
late var ModLoaderID;

DownloadGameDialog(BorderColour, NameController, Data, ModLoaderName, context) {
  ModLoaderID = ModLoader()
      .GetModLoader(ModLoader().ModLoaderNames.indexOf(ModLoaderName));
  //not the best way but at least it works
  Future.delayed(Duration(seconds: 0)).then((value) {
    //Is Fabric Loader
    if (ModLoaderID == ModLoader().Fabric) {
      try {
        FabricAPI().IsCompatibleVersion(Data["id"]).then((value) {
          if (value) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => FabricVersion(
                  BorderColour, NameController, Data, ModLoaderName, context),
            );
          } else {
            Navigator.pop(context);
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n.Format("gui.error.info")),
                    content: Text(i18n.Format(
                        "version.list.mod.loader.incompatible.error")),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n.Format("gui.ok")),
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
    } else if (ModLoaderID == ModLoader().Forge) {
      //Is Forge Loader

      try {
        ForgeAPI.IsCompatibleVersion(Data["id"]).then((value) {
          if (value) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => ForgeVersion(
                  BorderColour, NameController, Data, ModLoaderName, context),
            );
          } else {
            Navigator.pop(context);
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n.Format("gui.error.info")),
                    content: Text(i18n.Format(
                        "version.list.mod.loader.incompatible.error")),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n.Format("gui.ok")),
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
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AddInstanceDialog(
            BorderColour, NameController, Data, ModLoaderID, "null"),
      );
    }
  });
  return Center(child: CircularProgressIndicator());
}

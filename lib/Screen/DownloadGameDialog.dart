import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class DownloadGameDialog extends StatelessWidget {
  final Color borderColour;
  final TextEditingController nameController;
  final Map metaData;
  final ModLoaders loader;

  DownloadGameDialog(
      this.borderColour, this.nameController, this.metaData, this.loader);

  final Widget loading = Center(child: RWLLoading());

  @override
  Widget build(BuildContext context) {
    if (loader == ModLoaders.fabric) {
      return FutureBuilder(
          future: FabricAPI().isCompatibleVersion(metaData["id"]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == true) {
                return FabricVersion(borderColour, nameController, metaData);
              } else {
                return AlertDialog(
                  title: Text(I18n.format("gui.error.info")),
                  content: Text(I18n.format(
                      "version.list.mod.loader.incompatible.error")),
                  actions: <Widget>[
                    TextButton(
                      child: Text(I18n.format("gui.ok")),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              }
            } else {
              return loading;
            }
          });
    } else if (loader == ModLoaders.forge) {
      return FutureBuilder(
          future: ForgeAPI.isCompatibleVersion(metaData["id"]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == true) {
                return ForgeVersion(borderColour, nameController, metaData);
              } else {
                return AlertDialog(
                  title: Text(I18n.format("gui.error.info")),
                  content: Text(I18n.format(
                      "version.list.mod.loader.incompatible.error")),
                  actions: <Widget>[
                    TextButton(
                      child: Text(I18n.format("gui.ok")),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              }
            } else {
              return loading;
            }
          });
    } else {
      return AddInstanceDialog(
          borderColour, nameController, metaData, loader, "null");
    }
  }
}

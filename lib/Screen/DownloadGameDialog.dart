import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';

class DownloadGameDialog extends StatelessWidget {
  final Color borderColour;
  final TextEditingController nameController;
  final MCVersion version;
  final ModLoaders loader;

  const DownloadGameDialog(
      this.borderColour, this.nameController, this.version, this.loader);

  @override
  Widget build(BuildContext context) {
    if (loader == ModLoaders.fabric) {
      return FabricVersion(borderColour, nameController, version);
    } else if (loader == ModLoaders.forge) {
      return ForgeVersion(borderColour, nameController, version);
    } else {
      return AddInstanceDialog(
          borderColour, nameController, version, loader, "null");
    }
  }
}

import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';

class DownloadGameDialog extends StatelessWidget {
  final TextEditingController nameController;
  final MCVersion version;
  final ModLoaders loader;

  const DownloadGameDialog(
     this.nameController, this.version, this.loader);

  @override
  Widget build(BuildContext context) {
    if (loader == ModLoaders.fabric) {
      return FabricVersion( nameController, version);
    } else if (loader == ModLoaders.forge) {
      return ForgeVersion(nameController, version);
    } else {
      return AddInstanceDialog(nameController, version, loader, "null");
    }
  }
}

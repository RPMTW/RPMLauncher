import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/FabricVersion.dart';
import 'package:rpmlauncher/Widget/ForgeVersion.dart';
import 'package:flutter/material.dart';

class DownloadGameDialog extends StatelessWidget {
  final String instanceName;
  final MCVersion version;
  final ModLoaders loader;

  const DownloadGameDialog(this.instanceName, this.version, this.loader);

  @override
  Widget build(BuildContext context) {
    if (loader == ModLoaders.fabric) {
      return FabricVersion(instanceName, version);
    } else if (loader == ModLoaders.forge) {
      return ForgeVersion(instanceName, version);
    } else {
      return AddInstanceDialog(instanceName, version, loader, "null");
    }
  }
}

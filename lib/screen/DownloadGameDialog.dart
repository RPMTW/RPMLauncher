import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/widget/AddInstance.dart';
import 'package:rpmlauncher/widget/FabricVersion.dart';
import 'package:rpmlauncher/widget/ForgeVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/widget/WIPWidget.dart';

class DownloadGameDialog extends StatelessWidget {
  final String instanceName;
  final MCVersion version;
  final ModLoader loader;
  final MinecraftSide side;

  const DownloadGameDialog(
      this.instanceName, this.version, this.loader, this.side);

  @override
  Widget build(BuildContext context) {
    if (loader == ModLoader.fabric) {
      return FabricVersion(instanceName, version, side);
    } else if (loader == ModLoader.forge) {
      return ForgeVersion(instanceName, version);
    } else if (loader == ModLoader.paper) {
      return WiPWidget();
    } else {
      return AddInstanceDialog(instanceName, version, loader, null, side);
    }
  }
}

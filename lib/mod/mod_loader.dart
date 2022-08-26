import 'package:hive/hive.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

import '../util/i18n.dart';

part 'mod_loader.g.dart';

@HiveType(typeId: 1)
enum ModLoader {
  @HiveField(0)
  vanilla,
  @HiveField(1)
  fabric,
  @HiveField(2)
  forge,
  @HiveField(3)
  paper,
  @HiveField(4)
  unknown;

  const ModLoader();

  String get fixedString => name;

  String get i18nString {
    switch (this) {
      case ModLoader.vanilla:
        return I18n.format("version.list.mod.loader.vanilla");
      case ModLoader.fabric:
        return I18n.format("version.list.mod.loader.fabric");
      case ModLoader.forge:
        return I18n.format("version.list.mod.loader.forge");
      case ModLoader.paper:
        return I18n.format("version.list.mod.loader.paper");
      default:
        return I18n.format("version.list.mod.loader.unknown");
    }
  }

  List<MinecraftSide> supportedSides() {
    switch (this) {
      case ModLoader.vanilla:
        return [MinecraftSide.client, MinecraftSide.server];
      case ModLoader.fabric:
        return [MinecraftSide.client, MinecraftSide.server];
      case ModLoader.forge:
        return [MinecraftSide.client];
      case ModLoader.paper:
        return [MinecraftSide.server];
      default:
        return [MinecraftSide.client];
    }
  }

  bool supportInstall() {
    switch (this) {
      case ModLoader.vanilla:
        return true;
      case ModLoader.fabric:
        return true;
      case ModLoader.forge:
        return true;
      case ModLoader.paper:
        return true;
      default:
        return false;
    }
  }

  CurseForgeModLoaderType? toCurseForgeType() {
    try {
      return CurseForgeModLoaderType.values.byName(name);
    } catch (e) {
      return null;
    }
  }
}

class ModLoaderUttily {
  static ModLoader getByIndex(index) {
    switch (index) {
      case 0:
        return ModLoader.vanilla;
      case 1:
        return ModLoader.fabric;
      case 2:
        return ModLoader.forge;
      case 3:
        return ModLoader.paper;
      default:
        return ModLoader.vanilla;
    }
  }

  static ModLoader getByString(String loader) {
    try {
      return ModLoader.values.byName(loader);
    } catch (e) {
      return ModLoader.vanilla;
    }
  }

  static ModLoader getByI18nString(String modLoaderName) {
    return ModLoaderUttily.getByIndex(ModLoader.values
        .map((e) => e.i18nString)
        .toList()
        .indexOf(modLoaderName));
  }

  static int getIndexByLoader(ModLoader loader) {
    switch (loader) {
      case ModLoader.vanilla:
        return 0;
      case ModLoader.fabric:
        return 1;
      case ModLoader.forge:
        return 2;
      case ModLoader.paper:
        return 3;
      default:
        return 0;
    }
  }
}

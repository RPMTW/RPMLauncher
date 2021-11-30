import '../Utility/I18n.dart';

enum ModLoader { vanilla, fabric, forge, unknown }

extension ExtensionModLoader on ModLoader {
  String get fixedString => name;

  String get i18nString {
    switch (this) {
      case ModLoader.vanilla:
        return I18n.format("version.list.mod.loader.vanilla");
      case ModLoader.fabric:
        return I18n.format("version.list.mod.loader.fabric");
      case ModLoader.forge:
        return I18n.format("version.list.mod.loader.forge");
      default:
        return I18n.format("version.list.mod.loader.unknown");
    }
  }
}

class ModLoaderUttily {
  static List<String> i18nModLoaderNames = [
    I18n.format("version.list.mod.loader.vanilla"),
    I18n.format("version.list.mod.loader.fabric"),
    I18n.format("version.list.mod.loader.forge")
  ];

  static ModLoader getByIndex(index) {
    switch (index) {
      case 0:
        return ModLoader.vanilla;
      case 1:
        return ModLoader.fabric;
      case 2:
        return ModLoader.forge;
      default:
        return ModLoader.vanilla;
    }
  }

  static ModLoader getByString(String loader) {
    switch (loader) {
      case 'vanilla':
        return ModLoader.vanilla;
      case 'fabric':
        return ModLoader.fabric;
      case 'forge':
        return ModLoader.forge;
      case 'unknown':
        return ModLoader.unknown;
      default:
        return ModLoader.vanilla;
    }
  }

  static ModLoader getByI18nString(String modLoaderName) {
    return ModLoaderUttily.getByIndex(
        ModLoaderUttily.i18nModLoaderNames.indexOf(modLoaderName));
  }

  static int getIndexByLoader(ModLoader loader) {
    switch (loader) {
      case ModLoader.vanilla:
        return 0;
      case ModLoader.fabric:
        return 1;
      case ModLoader.forge:
        return 2;
      default:
        return 0;
    }
  }
}

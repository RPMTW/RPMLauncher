import '../Utility/i18n.dart';

enum ModLoaders { vanilla, fabric, forge, unknown }

extension ExtensionModLoader on ModLoaders {
  String get fixedString => name;

  String get i18nString {
    switch (this) {
      case ModLoaders.vanilla:
        return I18n.format("version.list.mod.loader.vanilla");
      case ModLoaders.fabric:
        return I18n.format("version.list.mod.loader.fabric");
      case ModLoaders.forge:
        return I18n.format("version.list.mod.loader.forge");
      default:
        return I18n.format("version.list.mod.loader.unknown");
    }
  }
}

class ModLoaderUttily {
  static List<String> modLoaderNames = [
    I18n.format("version.list.mod.loader.vanilla"),
    I18n.format("version.list.mod.loader.fabric"),
    I18n.format("version.list.mod.loader.forge")
  ];

  static ModLoaders getByIndex(index) {
    switch (index) {
      case 0:
        return ModLoaders.vanilla;
      case 1:
        return ModLoaders.fabric;
      case 2:
        return ModLoaders.forge;
      default:
        return ModLoaders.vanilla;
    }
  }

  static ModLoaders getByString(String loader) {
    switch (loader) {
      case 'vanilla':
        return ModLoaders.vanilla;
      case 'fabric':
        return ModLoaders.fabric;
      case 'forge':
        return ModLoaders.forge;
      case 'unknown':
        return ModLoaders.unknown;
      default:
        return ModLoaders.vanilla;
    }
  }

  static int getIndexByLoader(ModLoaders loader) {
    switch (loader) {
      case ModLoaders.vanilla:
        return 0;
      case ModLoaders.fabric:
        return 1;
      case ModLoaders.forge:
        return 2;
      default:
        return 0;
    }
  }
}

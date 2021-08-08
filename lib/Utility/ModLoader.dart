import 'i18n.dart';

class ModLoader {
  var ModLoaderNames = [
    i18n.Format("version.list.mod.loader.vanilla"),
    i18n.Format("version.list.mod.loader.fabric"),
    i18n.Format("version.list.mod.loader.forge")
  ];

  final String None = "vanilla";
  final String Fabric = "fabric";
  final String Forge = "forge";
  final String Unknown = "unknown";

  String GetModLoader(Index) {
    if (Index == 1) {
      return Fabric;
    } else if (Index == 2) {
      return Forge;
    } else {
      return None;
    }
  }

  int GetIndex(Loader) {
    if (Loader == None) {
      return 0;
    } else if (Loader == Fabric) {
      return 1;
    } else {
      return 2;
    }
  }

}

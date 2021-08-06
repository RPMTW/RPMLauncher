import 'i18n.dart';

class ModLoader {
  var ModLoaderNames = [
    i18n.Format("version.list.mod.loader.vanilla"),
    i18n.Format("version.list.mod.loader.fabric"),
    i18n.Format("version.list.mod.loader.forge")
  ];

  var None = "vanilla";
  var Fabric = "fabric";
  var Forge = "forge";

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

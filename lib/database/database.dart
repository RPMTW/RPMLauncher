import 'package:hive/hive.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';

class Database {
  static Database? _instance;
  static Database get instance => _instance!;

  final DataBox<String, ModInfo> modInfoBox;

  const Database._({required this.modInfoBox});

  static Future<void> init() async {
    Hive.init(GameRepository.getDatabaseDir().path);
    Hive.registerAdapter(ModInfoAdapter());
    Hive.registerAdapter(ConflictModAdapter());
    Hive.registerAdapter(ModLoaderAdapter());

    _instance = Database._(
        modInfoBox: await DataBox.open<String, ModInfo>('mod_info_index'));
  }
}

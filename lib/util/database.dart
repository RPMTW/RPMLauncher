import 'package:hive_flutter/hive_flutter.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';

class Database {
  static Database? _instance;
  static Database get instance => _instance!;

  final Box modInfoBox;

  const Database._({required this.modInfoBox});

  static Future<void> init() async {
    Hive.initFlutter();
    Hive.init(GameRepository.getDatabaseDir().path);
    Hive.registerAdapter(ModInfoAdapter());
    Hive.registerAdapter(ConflictModAdapter());
    Hive.registerAdapter(ModLoaderAdapter());
    Box modInfoBox = await Hive.openBox('mod_info_index');

    _instance = Database._(modInfoBox: modInfoBox);
  }
}

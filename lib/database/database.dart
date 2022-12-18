import 'package:hive/hive.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';

class Database {
  static Database? _instance;

  static Database get instance => _instance!;

  const Database._();

  static Future<void> init() async {
    Hive.init(GameRepository.getDatabaseDir().path);
    _instance = const Database._();
  }
}

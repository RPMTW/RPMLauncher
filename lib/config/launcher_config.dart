import 'dart:io';
import 'dart:math';

import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/config/interface_launcher_config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/i18n/launcher_language.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/util/updater.dart';

class LauncherConfig implements ILauncherConfig {
  const LauncherConfig();

  @override
  int get schemaVersion => ConfigHelper.get<int>('schema_version') ?? 1;

  @override
  set schemaVersion(int value) =>
      ConfigHelper.set<int>('schema_version', value);

  @override
  bool get isInit => ConfigHelper.get<bool>('init') ?? false;

  @override
  set isInit(bool value) => ConfigHelper.set<bool>('init', value);

  @override
  bool get autoInstallJava =>
      ConfigHelper.get<bool>('auto_install_java') ?? true;

  @override
  set autoInstallJava(bool value) =>
      ConfigHelper.set<bool>('auto_install_java', value);

  @override
  double get jvmMaxRam => ConfigHelper.get<double>('jvm_max_ram') ?? 4096.0;

  @override
  set jvmMaxRam(double value) => ConfigHelper.set<double>('jvm_max_ram', value);

  @override
  List<String> get jvmArgs => ConfigHelper.get<List<String>>('jvm_args') ?? [];

  @override
  set jvmArgs(List<String> value) =>
      ConfigHelper.set<List<String>>('jvm_args', value);

  @override
  LauncherLanguage get language {
    final code = ConfigHelper.get<String>('language');

    return LauncherLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => I18n.getSystemLanguage(),
    );
  }

  @override
  set language(LauncherLanguage value) =>
      ConfigHelper.set<String>('language', value.code);

  @override
  bool get checkAssetsIntegrity =>
      ConfigHelper.get<bool>('check_assets_integrity') ?? true;
  @override
  set checkAssetsIntegrity(bool value) =>
      ConfigHelper.set<bool>('check_assets_integrity', value);

  @override
  int get gameWindowWidth => ConfigHelper.get<int>('game_window_width') ?? 854;
  @override
  set gameWindowWidth(int value) =>
      ConfigHelper.set<int>('game_window_width', value);

  @override
  int get gameWindowHeight =>
      ConfigHelper.get<int>('game_window_height') ?? 480;
  @override
  set gameWindowHeight(int value) =>
      ConfigHelper.set<int>('game_window_height', value);

  @override
  int get gameLogMaxLineCount =>
      ConfigHelper.get<int>('game_log_max_line_count') ?? 300;
  @override
  set gameLogMaxLineCount(int value) =>
      ConfigHelper.set<int>('game_log_max_line_count', value);

  @override
  bool get showGameLogs => ConfigHelper.get<bool>('show_game_logs') ?? true;
  @override
  set showGameLogs(bool value) =>
      ConfigHelper.set<bool>('show_game_logs', value);

  @override
  bool get autoCloseGameLogsScreen =>
      ConfigHelper.get<bool>('auto_close_game_logs_screen') ?? true;
  @override
  set autoCloseGameLogsScreen(bool value) =>
      ConfigHelper.set<bool>('auto_close_game_logs_screen', value);

  @override
  bool get autoDownloadModDependencies =>
      ConfigHelper.get<bool>('auto_download_mod_dependencies') ?? true;
  @override
  set autoDownloadModDependencies(bool value) =>
      ConfigHelper.set<bool>('auto_download_mod_dependencies', value);

  @override
  int get themeId => ConfigHelper.get<int>('theme_id') ?? ThemeUtil.getSystem();
  @override
  set themeId(int value) => ConfigHelper.set<int>('theme_id', value);

  @override
  VersionTypes get updateChannel {
    final channel = ConfigHelper.get<String>('update_channel');

    return VersionTypes.values.firstWhere(
      (type) => type.name == channel,
      orElse: () => VersionTypes.stable,
    );
  }

  @override
  set updateChannel(VersionTypes value) =>
      ConfigHelper.set<String>('update_channel', value.name);

  @override
  Directory get launcherDataDir {
    final path = ConfigHelper.get<String>('launcher_data_dir');

    return path == null ? LauncherPath.defaultDataHome : Directory(path);
  }

  @override
  set launcherDataDir(Directory value) =>
      ConfigHelper.set<String>('launcher_data_dir', value.absolute.path);

  @override
  String get googleAnalyticsClientId =>
      ConfigHelper.get<String>('google_analytics_client_id') ??
      '${Random().nextInt(0x7FFFFFFF)}.${DateTime.now().millisecondsSinceEpoch / 1000}';

  @override
  set googleAnalyticsClientId(String value) =>
      ConfigHelper.set<String>('google_analytics_client_id', value);

  @override
  bool get autoFullScreen =>
      ConfigHelper.get<bool>('auto_full_screen') ?? false;

  @override
  set autoFullScreen(bool value) =>
      ConfigHelper.set<bool>('auto_full_screen', value);

  @override
  bool get checkAccountValidity =>
      ConfigHelper.get<bool>('check_account_validity') ?? true;

  @override
  set checkAccountValidity(bool value) =>
      ConfigHelper.set<bool>('check_account_validity', value);

  @override
  String? get wrapperCommand => ConfigHelper.get<String>('wrapper_command');

  @override
  set wrapperCommand(String? value) =>
      ConfigHelper.set<String>('wrapper_command', value);

  @override
  bool get discordRichPresence =>
      ConfigHelper.get<bool>('enable_discord_rpc') ?? true;

  @override
  set discordRichPresence(bool value) =>
      ConfigHelper.set<bool>('enable_discord_rpc', value);

  @override
  File? get backgroundImageFile {
    final path = ConfigHelper.get<String>('background_image_file');

    return (path == null || path.isEmpty) ? null : File(path);
  }

  @override
  set backgroundImageFile(File? value) =>
      ConfigHelper.set<String>('background_image_file', value?.absolute.path);
}

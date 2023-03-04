import 'dart:io';
import 'dart:math';

import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/config/interface_launcher_config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/i18n/launcher_language.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmlauncher/util/updater.dart';

class LauncherConfig implements ILauncherConfig {
  const LauncherConfig();

  @override
  int get schemaVersion => configHelper.getItem<int>('schema_version') ?? 1;

  @override
  set schemaVersion(int value) =>
      configHelper.setItem<int>('schema_version', value);

  @override
  bool get isInit => configHelper.getItem<bool>('init') ?? false;

  @override
  set isInit(bool value) => configHelper.setItem<bool>('init', value);

  @override
  bool get autoInstallJava =>
      configHelper.getItem<bool>('auto_install_java') ?? true;

  @override
  set autoInstallJava(bool value) =>
      configHelper.setItem<bool>('auto_install_java', value);

  @override
  double get jvmMaxRam => configHelper.getItem<double>('jvm_max_ram') ?? 4096.0;

  @override
  set jvmMaxRam(double value) =>
      configHelper.setItem<double>('jvm_max_ram', value);

  @override
  List<String> get jvmArgs =>
      configHelper.getItem<List<String>>('jvm_args') ?? [];

  @override
  set jvmArgs(List<String> value) =>
      configHelper.setItem<List<String>>('jvm_args', value);

  @override
  LauncherLanguage get language {
    final code = configHelper.getItem<String>('language');

    return LauncherLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => I18n.getSystemLanguage(),
    );
  }

  @override
  set language(LauncherLanguage value) =>
      configHelper.setItem<String>('language', value.code);

  @override
  bool get checkAssetsIntegrity =>
      configHelper.getItem<bool>('check_assets_integrity') ?? true;
  @override
  set checkAssetsIntegrity(bool value) =>
      configHelper.setItem<bool>('check_assets_integrity', value);

  @override
  int get gameWindowWidth =>
      configHelper.getItem<int>('game_window_width') ?? 854;
  @override
  set gameWindowWidth(int value) =>
      configHelper.setItem<int>('game_window_width', value);

  @override
  int get gameWindowHeight =>
      configHelper.getItem<int>('game_window_height') ?? 480;
  @override
  set gameWindowHeight(int value) =>
      configHelper.setItem<int>('game_window_height', value);

  @override
  int get gameLogMaxLineCount =>
      configHelper.getItem<int>('game_log_max_line_count') ?? 300;
  @override
  set gameLogMaxLineCount(int value) =>
      configHelper.setItem<int>('game_log_max_line_count', value);

  @override
  bool get showGameLogs => configHelper.getItem<bool>('show_game_logs') ?? true;
  @override
  set showGameLogs(bool value) =>
      configHelper.setItem<bool>('show_game_logs', value);

  @override
  bool get autoCloseGameLogsScreen =>
      configHelper.getItem<bool>('auto_close_game_logs_screen') ?? true;
  @override
  set autoCloseGameLogsScreen(bool value) =>
      configHelper.setItem<bool>('auto_close_game_logs_screen', value);

  @override
  bool get autoDownloadModDependencies =>
      configHelper.getItem<bool>('auto_download_mod_dependencies') ?? true;
  @override
  set autoDownloadModDependencies(bool value) =>
      configHelper.setItem<bool>('auto_download_mod_dependencies', value);

  @override
  int get themeId => RPMLThemeType.dark.index;
  // configHelper.getItem<int>('theme_id') ?? LauncherTheme.getSystem();
  @override
  set themeId(int value) => configHelper.setItem<int>('theme_id', value);

  @override
  VersionTypes get updateChannel {
    final channel = configHelper.getItem<String>('update_channel');

    return VersionTypes.values.firstWhere(
      (type) => type.name == channel,
      orElse: () => VersionTypes.stable,
    );
  }

  @override
  set updateChannel(VersionTypes value) =>
      configHelper.setItem<String>('update_channel', value.name);

  @override
  Directory get launcherDataDir {
    final path = configHelper.getItem<String>('launcher_data_dir');

    return path == null ? LauncherPath.defaultDataHome : Directory(path);
  }

  @override
  set launcherDataDir(Directory value) =>
      configHelper.setItem<String>('launcher_data_dir', value.absolute.path);

  @override
  String get googleAnalyticsClientId =>
      configHelper.getItem<String>('google_analytics_client_id') ??
      '${Random().nextInt(0x7FFFFFFF)}.${DateTime.now().millisecondsSinceEpoch / 1000}';

  @override
  set googleAnalyticsClientId(String value) =>
      configHelper.setItem<String>('google_analytics_client_id', value);

  @override
  bool get autoFullScreen =>
      configHelper.getItem<bool>('auto_full_screen') ?? false;

  @override
  set autoFullScreen(bool value) =>
      configHelper.setItem<bool>('auto_full_screen', value);

  @override
  bool get checkAccountValidity =>
      configHelper.getItem<bool>('check_account_validity') ?? true;

  @override
  set checkAccountValidity(bool value) =>
      configHelper.setItem<bool>('check_account_validity', value);

  @override
  String? get wrapperCommand => configHelper.getItem<String>('wrapper_command');

  @override
  set wrapperCommand(String? value) =>
      configHelper.setItem<String>('wrapper_command', value);

  @override
  bool get discordRichPresence =>
      configHelper.getItem<bool>('enable_discord_rpc') ?? true;

  @override
  set discordRichPresence(bool value) =>
      configHelper.setItem<bool>('enable_discord_rpc', value);

  @override
  File? get backgroundImageFile {
    final path = configHelper.getItem<String>('background_image_file');

    return (path == null || path.isEmpty) ? null : File(path);
  }

  @override
  set backgroundImageFile(File? value) => configHelper.setItem<String>(
      'background_image_file', value?.absolute.path);
}

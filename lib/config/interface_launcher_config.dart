import 'dart:io';

import 'package:rpmlauncher/i18n/launcher_language.dart';
import 'package:rpmlauncher/util/updater.dart';

/// The storage interface for the launcher configuration.
abstract class ILauncherConfig {
  /// Schema version of the launcher configuration.
  abstract int schemaVersion;

  /// Whether the launcher is working for the first time.
  abstract bool isInit;

  /// Whether auto install JAVA for Minecraft instances.
  abstract bool autoInstallJava;

  /// JVM max RAM.
  /// The unit is MB.
  abstract double jvmMaxRam;

  /// The JAM arguments to launch the instance.
  abstract List<String> jvmArgs;

  /// The language of the launcher.
  /// If the language is not set, the system language will be used.
  abstract LauncherLanguage language;

  /// Whether to check the assets integrity when launching the instance.
  /// If the check fails, the launcher will redownload the missing assets.
  abstract bool checkAssetsIntegrity;

  /// The window width of the game.
  abstract int gameWindowWidth;

  /// The window height of the game.
  abstract int gameWindowHeight;

  /// The maximum line count of the game logs.
  /// If the line count exceeds the limit, the oldest logs will be removed.
  abstract int gameLogMaxLineCount;

  /// Whether to show the game logs.
  abstract bool showGameLogs;

  /// Whether auto close the game logs screen when the game is exited.
  abstract bool autoCloseGameLogsScreen;

  /// Whether auto download the dependencies of the mods.
  abstract bool autoDownloadModDependencies;

  /// The id of the selected theme.
  abstract int themeId;

  /// The channel to update the launcher.
  abstract VersionTypes updateChannel;

  /// The directory to store the launcher data.
  abstract Directory launcherDataDir;

  /// The client id of Google analytics.
  abstract String googleAnalyticsClientId;

  /// Whether auto full screen the launcher window.
  abstract bool autoFullScreen;

  /// Whether to check the account validity when launching the instance.
  abstract bool checkAccountValidity;

  /// The wrapper command to launch the instance.
  abstract String? wrapperCommand;

  /// Whether to enable Discord Rich Presence.
  abstract bool discordRichPresence;

  /// The file of the background image.
  abstract File? backgroundImageFile;
}

import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/Game/JvmArgs.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/widget/settings/java_path.dart';

class _SettingScreenState extends State<SettingScreen> {
  Color get primaryColor => ThemeUtil.getTheme().colorScheme.primary;

  TextEditingController jvmArgsController = TextEditingController();
  TextEditingController gameWindowWidthController = TextEditingController();
  TextEditingController gameWindowHeightController = TextEditingController();
  TextEditingController wrapperCommandController = TextEditingController();
  TextEditingController gameLogMaxLineCountController = TextEditingController();

  late bool checkAssetsIntegrity;
  late bool showGameLogs;
  late bool autoDownloadModDependencies;
  late bool autoFullScreen;
  late bool checkAccountValidity;
  late bool autoCloseGameLogsScreen;
  late bool discordRichPresence;

  String? backgroundPath;
  double javaMaxRam = launcherConfig.jvmMaxRam;

  VersionTypes updateChannel = launcherConfig.updateChannel;

  int _selectedIndex = 0;

  @override
  void initState() {
    checkAccountValidity = launcherConfig.checkAccountValidity;
    autoCloseGameLogsScreen = launcherConfig.autoCloseGameLogsScreen;
    checkAssetsIntegrity = launcherConfig.checkAssetsIntegrity;
    showGameLogs = launcherConfig.showGameLogs;
    autoDownloadModDependencies = launcherConfig.autoDownloadModDependencies;
    autoFullScreen = launcherConfig.autoFullScreen;
    discordRichPresence = launcherConfig.discordRichPresence;

    gameWindowWidthController.text = launcherConfig.gameWindowWidth.toString();
    gameWindowHeightController.text =
        launcherConfig.gameWindowHeight.toString();
    gameLogMaxLineCountController.text =
        launcherConfig.gameLogMaxLineCount.toString();
    wrapperCommandController.text = launcherConfig.wrapperCommand ?? "";
    jvmArgsController.text = JvmArgs.fromList(launcherConfig.jvmArgs).args;
    super.initState();
  }

  @override
  void dispose() {
    jvmArgsController.dispose();
    gameWindowWidthController.dispose();
    gameWindowHeightController.dispose();
    wrapperCommandController.dispose();
    gameLogMaxLineCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: FloatingActionButton(
                tooltip: I18n.format("gui.back"),
                elevation: 0,
                onPressed: () {
                  navigator.pop();
                },
                child: const Icon(Icons.arrow_back),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.code_rounded),
                selectedIcon: const Icon(Icons.code),
                label: I18nText('settings.java.title'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.web_asset_rounded),
                selectedIcon: const Icon(Icons.web_asset),
                label: I18nText('settings.appearance.title'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: I18nText('settings.advanced.title'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bug_report_outlined),
                selectedIcon: const Icon(Icons.bug_report),
                label: I18nText('settings.debug.title'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: I18nText('settings.title'),
                  centerTitle: true,
                  leading: const SizedBox(),
                ),
                if (_selectedIndex == 0) const _JavaSettings(),
              ],
            ),
          )
        ],
      ),
    ));
  }
}

class SettingScreen extends StatefulWidget {
  static const String route = "/settings";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _JavaSettings extends StatefulWidget {
  const _JavaSettings();

  @override
  State<_JavaSettings> createState() => _JavaSettingsState();
}

class _JavaSettingsState extends State<_JavaSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(children: [
      const JavaPathWidget(),
      const Divider(),
      SwitchListTile(
        value: launcherConfig.autoInstallJava,
        onChanged: (value) {
          setState(() {
            launcherConfig.autoInstallJava = value;
          });
        },
        title: Text(
          I18n.format("settings.java.auto"),
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    ]));
  }
}

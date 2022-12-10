import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/widget/memory_slider.dart';
import 'package:rpmlauncher/widget/settings/java_path.dart';
import 'package:rpmlauncher/widget/settings/jvm_args_settings.dart';

class _SettingScreenState extends State<SettingScreen> {
  Color get primaryColor => ThemeUtil.getTheme().colorScheme.primary;

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
    wrapperCommandController.text = launcherConfig.wrapperCommand ?? '';
    super.initState();
  }

  @override
  void dispose() {
    gameWindowWidthController.dispose();
    gameWindowHeightController.dispose();
    wrapperCommandController.dispose();
    gameLogMaxLineCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 100.0, vertical: 60.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                child: FloatingActionButton(
                  tooltip: I18n.format('gui.close'),
                  elevation: 0,
                  onPressed: () {
                    navigator.pop();
                  },
                  child: const Icon(Icons.close),
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
            Flexible(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: I18nText('settings.title'),
                        centerTitle: true,
                        leading: const SizedBox(),
                      ),
                      const Padding(padding: EdgeInsets.all(5.0)),
                      if (_selectedIndex == 0) const _JavaSettings(),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SettingScreen extends StatefulWidget {
  static const String route = '/settings';

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
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SafeArea(
        child: Column(children: [
      I18nText(
        'settings.java.path',
        style: titleStyle,
        textAlign: TextAlign.center,
      ),
      const JavaPathSettings(),
      const Divider(),
      SwitchListTile(
        value: launcherConfig.autoInstallJava,
        onChanged: (value) {
          setState(() {
            launcherConfig.autoInstallJava = value;
          });
        },
        title: Text(
          I18n.format('settings.java.auto'),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      const Divider(),
      MemorySlider(
          value: launcherConfig.jvmMaxRam,
          onChanged: (memory) {
            launcherConfig.jvmMaxRam = memory;
          }),
      const Divider(),
      JVMArgsSettings(
          value: launcherConfig.jvmArgs,
          onChanged: (value) {
            launcherConfig.jvmArgs = value;
          })
    ]));
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/language_selector.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/widget/memory_slider.dart';
import 'package:rpmlauncher/widget/rpmtw_design/rml_text_field.dart';
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
                      if (_selectedIndex == 1) const _AppearanceSettings(),
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

class _AppearanceSettings extends StatefulWidget {
  const _AppearanceSettings();

  @override
  State<_AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<_AppearanceSettings> {
  late TextEditingController gameWindowWidthController;
  late TextEditingController gameWindowHeightController;

  @override
  void initState() {
    gameWindowWidthController =
        TextEditingController(text: launcherConfig.gameWindowWidth.toString());
    gameWindowHeightController =
        TextEditingController(text: launcherConfig.gameWindowHeight.toString());
    super.initState();
  }

  @override
  void dispose() {
    gameWindowWidthController.dispose();
    gameWindowHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Column(
      children: [
        LanguageSelectorWidget(
          onChanged: () => setState(() {}),
        ),
        const Divider(),
        Text(
          I18n.format("settings.appearance.theme"),
          style: titleStyle,
        ),
        SelectorThemeWidget(
          themeString: ThemeUtil.toI18nString(ThemeUtil.getThemeEnumByConfig()),
          setWidgetState: setState,
        ),
        const Divider(),
        Text(
          I18n.format("settings.appearance.background.title"),
          style: titleStyle,
        ),
        Text(
            launcherConfig.backgroundImageFile?.path ??
                I18n.format("gui.default"),
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null) {
                    PlatformFile file = result.files.single;
                    launcherConfig.backgroundImageFile = File(file.path!);
                  }
                  setState(() {});
                },
                child:
                    Text(I18n.format("settings.appearance.background.pick"))),
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: () {
                  launcherConfig.backgroundImageFile = null;
                  setState(() {});
                },
                child:
                    Text(I18n.format("settings.appearance.background.reset"))),
          ],
        ),
        const Divider(),
        Text(
          I18n.format("settings.appearance.window.size.title"),
          style: titleStyle,
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          children: [
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: RMLTextField(
                textAlign: TextAlign.center,
                controller: gameWindowWidthController,
                hintText: "854",
                verify: (value) => int.tryParse(value) != null,
                onChanged: (value) async {
                  launcherConfig.gameWindowWidth = int.tryParse(value) ?? 854;
                },
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            const Icon(Icons.clear),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: RMLTextField(
                textAlign: TextAlign.center,
                controller: gameWindowHeightController,
                hintText: "480",
                verify: (value) => int.tryParse(value) != null,
                onChanged: (value) async {
                  launcherConfig.gameWindowHeight = int.tryParse(value) ?? 480;
                },
              ),
            ),
            const SizedBox(
              width: 12,
            ),
          ],
        )
      ],
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/language_selector.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/ui/widget/memory_slider.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/on_close.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/rpml_text_field.dart';
import 'package:rpmlauncher/ui/widget/settings/java_path.dart';
import 'package:rpmlauncher/ui/widget/settings/jvm_args_settings.dart';
import 'package:rpmlauncher/ui/widget/settings/theme_selector.dart';

class _SettingScreenState extends State<SettingScreen> {
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
        clipBehavior: Clip.antiAlias,
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
                      const SizedBox(height: 8),
                      if (_selectedIndex == 0) const _JavaSettings(),
                      if (_selectedIndex == 1) const _AppearanceSettings(),
                      if (_selectedIndex == 2) const _AdvancedSettings(),
                      if (_selectedIndex == 3) const _DebugOption(),
                      const SizedBox(height: 18)
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

  const SettingScreen({super.key});

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
          I18n.format('settings.appearance.theme'),
          style: titleStyle,
        ),
        const SizedBox(height: 12),
        const ThemeSelector(),
        const Divider(),
        Text(
          I18n.format('settings.appearance.background.title'),
          style: titleStyle,
        ),
        Text(
            launcherConfig.backgroundImageFile?.path ??
                I18n.format('gui.default'),
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
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
                    Text(I18n.format('settings.appearance.background.pick'))),
            const SizedBox(width: 10),
            OutlinedButton(
                onPressed: () {
                  launcherConfig.backgroundImageFile = null;
                  setState(() {});
                },
                child:
                    Text(I18n.format('settings.appearance.background.reset'))),
          ],
        ),
        const Divider(),
        Text(
          I18n.format('settings.appearance.window.size.title'),
          style: titleStyle,
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: RPMLTextField(
                textAlign: TextAlign.center,
                controller: gameWindowWidthController,
                hintText: '854',
                verify: (value) => int.tryParse(value) != null,
                onChanged: (value) async {
                  launcherConfig.gameWindowWidth = int.tryParse(value) ?? 854;
                },
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.clear),
            const SizedBox(width: 12),
            SizedBox(
              width: 280,
              child: RPMLTextField(
                textAlign: TextAlign.center,
                controller: gameWindowHeightController,
                hintText: '480',
                verify: (value) => int.tryParse(value) != null,
                onChanged: (value) async {
                  launcherConfig.gameWindowHeight = int.tryParse(value) ?? 480;
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _AdvancedSettings extends StatefulWidget {
  const _AdvancedSettings();

  @override
  State<_AdvancedSettings> createState() => _AdvancedSettingsState();
}

class _AdvancedSettingsState extends State<_AdvancedSettings> {
  late TextEditingController gameLogMaxLineCountController;
  late TextEditingController wrapperCommandController;

  @override
  void initState() {
    gameLogMaxLineCountController = TextEditingController(
        text: launcherConfig.gameLogMaxLineCount.toString());
    wrapperCommandController =
        TextEditingController(text: launcherConfig.wrapperCommand);

    super.initState();
  }

  @override
  void dispose() {
    gameLogMaxLineCountController.dispose();
    wrapperCommandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Column(
      children: [
        I18nText('settings.advanced.tips',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.red),
            textAlign: TextAlign.center),
        const Divider(),
        ListTile(
          title: I18nText(
            'settings.advanced.datahome',
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          subtitle: SelectableText(dataHome.absolute.path,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
              )),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                  onPressed: () async {
                    final path = await FilePicker.platform.getDirectoryPath();

                    if (path != null) {
                      launcherConfig.launcherDataDir = Directory(path);
                      setState(() {});

                      if (context.mounted) {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) =>
                                const _ChangeDataHomeSuccessful());
                      }
                    }
                  },
                  icon: const Icon(Icons.folder),
                  label: I18nText('settings.advanced.datahome.change')),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                  onPressed: () {
                    launcherConfig.launcherDataDir =
                        LauncherPath.defaultDataHome;
                    setState(() {});
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const _ChangeDataHomeSuccessful());
                  },
                  icon: const Icon(Icons.restore),
                  label: I18nText('settings.advanced.datahome.restore'))
            ],
          ),
        ),
        const Divider(),
        SwitchListTile(
          value: launcherConfig.checkAssetsIntegrity,
          onChanged: (value) {
            setState(() {
              launcherConfig.checkAssetsIntegrity = value;
            });
          },
          title: I18nText('settings.advanced.assets.check',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.showGameLogs,
          onChanged: (value) {
            setState(() {
              launcherConfig.showGameLogs = value;
            });
          },
          title: I18nText('settings.advanced.show_log',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.autoDownloadModDependencies,
          onChanged: (value) {
            setState(() {
              launcherConfig.autoDownloadModDependencies = value;
            });
          },
          title: I18nText('settings.advanced.auto_dependencies',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.autoFullScreen,
          onChanged: (value) {
            setState(() {
              launcherConfig.autoFullScreen = value;
            });
          },
          title: I18nText('settings.advanced.auto_full_screen',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.checkAccountValidity,
          onChanged: (value) {
            setState(() {
              launcherConfig.checkAccountValidity = value;
            });
          },
          title: I18nText('settings.advanced.validate_account',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.autoCloseGameLogsScreen,
          onChanged: (value) {
            setState(() {
              launcherConfig.autoCloseGameLogsScreen = value;
            });
          },
          title: I18nText('settings.advanced.auto_close_log_screen',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        SwitchListTile(
          value: launcherConfig.discordRichPresence,
          onChanged: (value) {
            setState(() {
              launcherConfig.discordRichPresence = value;
            });
          },
          title: I18nText('settings.advanced.discord_rpc',
              style: titleStyle, textAlign: TextAlign.center),
        ),
        const Divider(),
        I18nText('settings.advanced.update_channel',
            style: titleStyle, textAlign: TextAlign.center),
        SegmentedButton<VersionTypes>(
          segments: [
            ButtonSegment(
              value: VersionTypes.stable,
              icon: const Icon(Icons.check_circle),
              label: Text(Updater.toI18nString(VersionTypes.stable)),
            ),
            ButtonSegment(
              value: VersionTypes.dev,
              icon: const Icon(Icons.bug_report),
              label: Text(Updater.toI18nString(VersionTypes.dev)),
            ),
          ],
          selected: {launcherConfig.updateChannel},
          onSelectionChanged: (newSelection) {
            setState(() {
              launcherConfig.updateChannel = newSelection.first;
            });
          },
        ),
        const Divider(),
        ListTile(
          title: I18nText('settings.advanced.max.log',
              style: titleStyle, textAlign: TextAlign.center),
          trailing: SizedBox(
            width: 300,
            child: RPMLTextField(
              textAlign: TextAlign.center,
              controller: gameLogMaxLineCountController,
              verify: (value) => int.tryParse(value) != null,
              hintText: '300',
              onChanged: (value) async {
                launcherConfig.gameLogMaxLineCount = int.parse(value);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: I18nText('settings.advanced.wrapper_command',
              style: titleStyle, textAlign: TextAlign.center),
          trailing: SizedBox(
            width: 300,
            child: RPMLTextField(
              textAlign: TextAlign.center,
              controller: wrapperCommandController,
              hintText: 'Executable program',
              onChanged: (value) {
                launcherConfig.wrapperCommand = value.isEmpty ? null : value;
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangeDataHomeSuccessful extends StatelessWidget {
  const _ChangeDataHomeSuccessful({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText('settings.advanced.datahome.change.successful'),
      actions: [
        OkClose(
          onOk: () {
            Util.exit(0);
          },
        )
      ],
    );
  }
}

class _DebugOption extends StatefulWidget {
  const _DebugOption();

  @override
  State<_DebugOption> createState() => _DebugOptionState();
}

class _DebugOptionState extends State<_DebugOption> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        I18nText('settings.advanced.tips',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.red),
            textAlign: TextAlign.center),
        const Divider(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton.extended(
                onPressed: () async {
                  LauncherPath.currentConfigHome.deleteSync(recursive: true);
                  if (dataHome.existsSync()) {
                    dataHome.deleteSync(recursive: true);
                  }

                  await Util.exit(0);
                },
                label: I18nText('settings.debug.delete_all_data',
                    style: Theme.of(context).textTheme.titleLarge)),
          ],
        ),
      ],
    );
  }
}

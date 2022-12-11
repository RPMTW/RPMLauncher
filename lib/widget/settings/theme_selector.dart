import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/theme.dart';

class ThemeSelector extends StatefulWidget {
  const ThemeSelector();

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: ThemeUtil.toInt(Themes.light),
          label: Text(ThemeUtil.toI18nString(Themes.light)),
          icon: const Icon(Icons.wb_sunny),
        ),
        ButtonSegment(
          value: ThemeUtil.toInt(Themes.dark),
          label: Text(ThemeUtil.toI18nString(Themes.dark)),
          icon: const Icon(Icons.nightlight_round),
        ),
      ],
      selected: {launcherConfig.themeId},
      onSelectionChanged: (newSelection) async {
        final themeId = newSelection.first;
        launcherConfig.themeId = themeId;
        await DynamicTheme.of(context)!.setTheme(themeId);
        await WindowHandler.setTheme(themeId);
        setState(() {});
      },
    );
  }
}

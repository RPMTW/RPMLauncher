import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({super.key});

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: RPMLThemeType.light.index,
          label: Text(LauncherTheme.toI18nString(RPMLThemeType.light)),
          icon: const Icon(Icons.wb_sunny),
        ),
        ButtonSegment(
          value: RPMLThemeType.dark.index,
          label: Text(LauncherTheme.toI18nString(RPMLThemeType.dark)),
          icon: const Icon(Icons.nightlight_round),
        ),
      ],
      selected: {launcherConfig.themeId},
      onSelectionChanged: (newSelection) async {
        final themeId = newSelection.first;
        launcherConfig.themeId = themeId;
        LauncherTheme.of(context).setTheme(LauncherTheme.getTypeById(themeId));
        setState(() {});
      },
    );
  }
}

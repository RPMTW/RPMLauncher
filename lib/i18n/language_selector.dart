import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/i18n/launcher_language.dart';
import 'package:rpmlauncher/view/row_scroll_view.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final Function()? onChanged;

  const LanguageSelectorWidget({
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  LauncherLanguage language = launcherConfig.language;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.format("settings.appearance.language.title"),
          style: const TextStyle(fontSize: 20.0, color: Colors.lightBlue),
        ),
        RowScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language),
              const SizedBox(
                width: 10,
              ),
              DropdownButton<LauncherLanguage>(
                value: language,
                onChanged: (value) {
                  language = value!;
                  launcherConfig.language = language;
                  setState(() {});
                  widget.onChanged?.call();
                },
                items: LauncherLanguage.values.map((value) {
                  return DropdownMenuItem<LauncherLanguage>(
                    value: value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value.name),
                        const SizedBox(
                          width: 10,
                        ),
                        value.getFlagWidget(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/Game/jvm_args.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';

class JVMArgsSettings extends StatefulWidget {
  final List<String> value;
  final Function(List<String>) onChanged;
  const JVMArgsSettings(
      {super.key, required this.value, required this.onChanged});

  @override
  State<JVMArgsSettings> createState() => _JVMArgsSettingsState();
}

class _JVMArgsSettingsState extends State<JVMArgsSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      I18nText(
        'settings.java.jvm.args',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 5),
      FractionallySizedBox(
        widthFactor: 0.6,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: RPMTextField(
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(JvmArgs(args: value).toList());
                },
              ),
            ),
            const SizedBox(width: 20),
            FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add'))
          ],
        ),
      ),
    ]);
  }
}

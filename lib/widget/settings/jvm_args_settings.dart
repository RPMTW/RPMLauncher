import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/Game/jvm_args.dart';

class JVMArgsSettings extends StatefulWidget {
  final List<String> value;
  final Function(List<String>) onChanged;
  const JVMArgsSettings(
      {super.key, required this.value, required this.onChanged});

  @override
  State<JVMArgsSettings> createState() => _JVMArgsSettingsState();
}

class _JVMArgsSettingsState extends State<JVMArgsSettings> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller =
        TextEditingController(text: JvmArgs.fromList(widget.value).args);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      const SizedBox(height: 8),
      FractionallySizedBox(
        widthFactor: 0.6,
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
              hintText: I18n.format('settings.java.jvm.args.hint'),
              border: const OutlineInputBorder()),
          textAlign: TextAlign.center,
          onChanged: (value) {
            setState(() {});
            widget.onChanged(JvmArgs(args: value).toList());
          },
        ),
      )
    ]);
  }
}

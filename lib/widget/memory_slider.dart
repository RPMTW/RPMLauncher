import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/widget/rwl_loading.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';

class MemorySlider extends StatefulWidget {
  final void Function(double) onChanged;
  final double value;

  const MemorySlider({Key? key, required this.onChanged, required this.value})
      : super(key: key);

  @override
  State<MemorySlider> createState() => _MemorySliderState();
}

class _MemorySliderState extends State<MemorySlider> {
  late double memory;

  @override
  void initState() {
    memory = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemoryInfo>(
        future: RPMLauncherPlugin.getTotalPhysicalMemory(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final MemoryInfo info = snapshot.data!;
            final double physical = info.physical;
            final double formattedPhysical = info.formattedPhysical.toDouble();

            /// If the computer memory size changes, reset it
            if (memory > formattedPhysical) {
              memory = 1024;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  I18n.format("settings.java.ram.max"),
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.lightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${I18n.format("settings.java.ram.physical")} ${physical.toInt()} MB (${(physical / 1024).toStringAsFixed(2)} GB)",
                ),
                Slider(
                  value: memory,
                  onChanged: (double value) {
                    memory = value;
                    setState(() {});
                    widget.onChanged(value);
                  },
                  activeColor: ThemeUtil.getTheme().colorScheme.primary,
                  min: 1024,
                  max: formattedPhysical,
                  divisions: (formattedPhysical ~/ 1024) - 1,
                  label: "${memory.toInt()} MB (${memory ~/ 1024}GB)",
                ),
              ],
            );
          } else {
            return const RWLLoading();
          }
        });
  }
}

import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class RoundDivider extends StatelessWidget {
  final double size;
  final Color? color;

  const RoundDivider({super.key, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
            decoration: BoxDecoration(
          border: Border.all(
              color: color ?? context.theme.borderColor, width: size),
        )));
  }
}

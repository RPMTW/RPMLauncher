import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class BlurBlock extends StatelessWidget {
  final Widget child;
  final double blur;
  final double colorOpacity;
  final BoxConstraints? constraints;

  const BlurBlock(
      {super.key,
      required this.child,
      this.blur = 15,
      this.colorOpacity = 0.3,
      this.constraints});

  @override
  Widget build(BuildContext context) {
    return Blur(
      blur: blur,
      blurColor: context.theme.mainColor,
      colorOpacity: colorOpacity,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      overlay: child,
      child: Container(constraints: constraints),
    );
  }
}

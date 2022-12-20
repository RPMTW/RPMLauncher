import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class Background extends StatefulWidget {
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  ImageProvider image = const AssetImage(
    "assets/images/background.png",
  );

  @override
  void initState() {
    if (launcherConfig.backgroundImageFile != null) {
      try {
        image = FileImage(launcherConfig.backgroundImageFile!);
      } catch (e) {}
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(),
        ),
      ),
      Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.8, -1.0),
            end: Alignment(0.6, 1.0),
            colors: [
              Color.fromARGB(0, 30, 30, 30),
              Color(0XFF263222),
            ],
            tileMode: TileMode.mirror,
          ),
        ),
      ),
      Opacity(
        opacity: 0.03,
        child: ColoredBox(color: context.theme.mainColor, child: Container()),
      ),
      widget.child
    ]);
  }
}

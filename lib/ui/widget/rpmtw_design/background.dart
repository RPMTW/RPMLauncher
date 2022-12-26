import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';

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
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
      ),
      child: widget.child,
    );
  }
}

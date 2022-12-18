import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';

class Background extends StatelessWidget {
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Builder(builder: (context) {
          Image defaultImage = Image.asset(
            "assets/images/background.png",
            fit: BoxFit.fill,
          );

          if (launcherConfig.backgroundImageFile == null) {
            return defaultImage;
          } else {
            try {
              return Image.file(
                launcherConfig.backgroundImageFile!,
                fit: BoxFit.fill,
              );
            } catch (e) {
              return defaultImage;
            }
          }
        }),
      ),
      Opacity(
        opacity: 0.18,
        child: ColoredBox(
          color: Colors.black,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
        ),
      ),
      child
    ]);
  }
}

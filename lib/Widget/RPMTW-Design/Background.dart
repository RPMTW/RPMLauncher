import 'dart:io';

import 'package:flutter/material.dart';

import '../../Utility/Config.dart';

class Background extends StatelessWidget {
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Builder(builder: (context){
      print(Config.getValue("background").toString().isNotEmpty);
        if (Config.getValue("background")==null||Config.getValue("background").toString().isEmpty) {
          return Container();
        }else{
          return ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: Image.file(
              File(Config.getValue("background")),
              fit: BoxFit.fill,
            ),
          );
        }

      }),
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

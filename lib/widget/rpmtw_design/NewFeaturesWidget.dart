import 'package:flutter/material.dart';

class NewFeaturesWidget extends StatelessWidget {
  const NewFeaturesWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const Positioned(
          bottom: 11,
          left: 20,
          child: Icon(Icons.star_rate, color: Colors.yellow, size: 21),
        ),
      ],
    );
  }
}

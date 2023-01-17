import 'package:flutter/material.dart';

class RowScrollView extends StatelessWidget {
  late ScrollController _controller;
  Alignment alignment;
  Widget child;

  RowScrollView({
    Key? key,
    ScrollController? controller,
    this.alignment = Alignment.center,
    required this.child,
  }) : super(key: key) {
    _controller = controller ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: alignment,
        child: Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: child)));
  }
}

import 'package:flutter/material.dart';

class RowScrollView extends StatelessWidget {
  late ScrollController _controller;
  bool center;
  Row child;

  RowScrollView({
    Key? key,
    ScrollController? controller,
    this.center = true,
    required this.child,
  }) : super(key: key) {
    _controller = controller ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: child)));
  }
}

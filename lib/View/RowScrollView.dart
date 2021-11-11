import 'package:flutter/material.dart';

class RowScrollView extends StatelessWidget {
  late ScrollController _controller;
  Row child;

  RowScrollView({
    Key? key,
    ScrollController? controller,
    required this.child,
  }) : super(key: key) {
    _controller = controller ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: child)));
  }
}

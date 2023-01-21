import 'package:flutter/cupertino.dart';

class SlideRoute extends CupertinoPageRoute {
  SlideRoute({required super.builder}) : super();

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
        opacity: animation,
        child: super
            .buildTransitions(context, animation, secondaryAnimation, child));
  }
}

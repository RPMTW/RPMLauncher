import 'package:flutter/material.dart';

class SlideTransitionRoute<T> extends MaterialPageRoute<T> {
  SlideTransitionRoute(
      {required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
        position: animation.drive(Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        )),
        child: child);
  }
}

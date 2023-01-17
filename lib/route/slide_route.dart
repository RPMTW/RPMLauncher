import 'package:flutter/material.dart';

class SlideRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  SlideRoute({required this.builder})
      : super(pageBuilder: (context, animation, secondaryAnimation) {
          return builder.call(context);
        }, transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, -1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        });
}

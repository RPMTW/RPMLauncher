import 'package:flutter/material.dart';

class SlideRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  final Offset begin;

  SlideRoute({required this.builder, required this.begin})
      : super(pageBuilder: (context, animation, secondaryAnimation) {
          return builder.call(context);
        }, transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        });
}

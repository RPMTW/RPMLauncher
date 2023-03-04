import 'package:flutter/material.dart';

class FadeRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  FadeRoute({required this.builder, super.settings})
      : super(pageBuilder: (context, animation, secondaryAnimation) {
          return builder.call(context);
        }, transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        });
}

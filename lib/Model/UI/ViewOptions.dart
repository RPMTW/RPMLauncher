import 'dart:collection';

import 'package:flutter/cupertino.dart';

class ViewOptions extends IterableBase<ViewOptionTile> {
  List<ViewOptionTile> options = [];

  ViewOptions(this.options);

  @override
  Iterator<ViewOptionTile> get iterator => options.iterator;
}

class ViewOptionTile {
  final bool show;
  final String? title;
  final Widget? icon;
  final String? description;

  ViewOptionTile(
      {required this.title,
      required this.icon,
      this.description,
      this.show = true});

  factory ViewOptionTile.show() {
    return ViewOptionTile(title: null, icon: null, show: true);
  }
}

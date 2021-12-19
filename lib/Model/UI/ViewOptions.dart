import 'dart:collection';

import 'package:flutter/cupertino.dart';

class ViewOptions extends IterableBase<ViewOptionTile> {
  List<ViewOptionTile> options = [];

  ViewOptions(this.options);

  @override
  Iterator<ViewOptionTile> get iterator => options.iterator;
}

class ViewOptionTile {
  final bool empty;
  final String? title;
  final Widget? icon;
  final String? description;

  ViewOptionTile(
      {required this.title,
      required this.icon,
      this.description,
      this.empty = false});

  factory ViewOptionTile.empty() {
    return ViewOptionTile(title: null, icon: null, empty: true);
  }
}

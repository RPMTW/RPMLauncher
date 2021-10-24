import 'dart:collection';

import 'package:flutter/cupertino.dart';

class ViewOptions extends IterableBase<ViewOption> {
  List<ViewOption> options = [];

  ViewOptions(this.options);

  @override
  Iterator<ViewOption> get iterator => options.iterator;
}

class ViewOption {
  final bool empty;
  final String? title;
  final Widget? icon;
  final String? description;

  ViewOption(
      {required this.title,
      required this.icon,
      this.description,
      this.empty = false});

  factory ViewOption.empty() {
    return ViewOption(title: null, icon: null, empty: true);
  }
}

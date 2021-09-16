import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

class OptionsView extends StatefulWidget {
  final List<Widget> optionWidgets;
  final Options options;
  final List<double?>? weights;
  final double gripSize;

  OptionsView({
    Key? key,
    required this.optionWidgets,
    required this.options,
    required this.weights,
    required this.gripSize,
  }) : super(key: key);

  @override
  State<OptionsView> createState() => _OptionsViewState(
      optionWidgets: optionWidgets,
      options: options,
      weights: weights,
      gripSize: gripSize);
}

class _OptionsViewState extends State<OptionsView> {
  final List<Widget> optionWidgets;
  final Options options;
  final List<double?>? weights;
  final double gripSize;

  _OptionsViewState(
      {required this.optionWidgets,
      required this.options,
      required this.weights,
      required this.gripSize});

  PageController _pageController = PageController();
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SplitView(
        children: [
          StatefulBuilder(builder: (context, _setState) {
            return ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  Option option = options.options[index];
                  return ListTile(
                    title: Text(option.title),
                    leading: option.icon,
                    onTap: () async {
                      await _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                      _setState(() {});
                    },
                    tileColor: selectedIndex == index
                        ? Colors.white12
                        : Theme.of(context).scaffoldBackgroundColor,
                  );
                });
          }),
          PageView.builder(
              controller: _pageController,
              itemCount: optionWidgets.length,
              itemBuilder: (context, int Index) {
                selectedIndex = Index;
                return optionWidgets[Index];
              })
        ],
        gripSize: 3,
        controller: SplitViewController(weights: weights),
        viewMode: SplitViewMode.Horizontal);
  }
}

class Options extends IterableBase<Option> {
  List<Option> options = [];

  Options(this.options);

  @override
  Iterator<Option> get iterator => options.iterator;
}

class Option {
  final String title;
  final Widget icon;

  Option({required this.title, required this.icon});
}

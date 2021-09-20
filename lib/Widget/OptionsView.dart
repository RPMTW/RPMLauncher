// ignore_for_file: unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:split_view/split_view.dart';

class OptionsView extends StatefulWidget {
  final List<Widget> Function(StateSetter) optionWidgets;
  final ViewOptions Function() options;
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
  final List<Widget> Function(StateSetter) optionWidgets;
  final ViewOptions Function() options;
  final List<double?>? weights;
  final double gripSize;

  _OptionsViewState(
      {required this.optionWidgets,
      required this.options,
      required this.weights,
      required this.gripSize});

  PageController _pageController = PageController();
  int selectedIndex = 0;

  Future<void> _animateToPage(int index) async {
    int Page = _pageController.page!.toInt();
    if ((Page - index == 1) || Page - index == -1) {
      await _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplitView(
        children: [
          StatefulBuilder(builder: (context, setOptionState) {
            return ListView.builder(
                itemCount: options.call().length,
                itemBuilder: (context, index) {
                  ViewOption option = options.call().options[index];
                  Widget _optionWidget = ListTile(
                    title: Text(option.title),
                    leading: option.icon,
                    onTap: () async {
                      selectedIndex = index;
                      setOptionState(() {});
                      // _pageController.jumpToPage(index);
                      await _animateToPage(index);
                    },
                    tileColor: selectedIndex == index
                        ? Colors.white12
                        : Theme.of(context).scaffoldBackgroundColor,
                    trailing: Builder(builder: (context) {
                      if (option.description != null) {
                        return Tooltip(
                          showDuration: Duration(milliseconds: 20),
                          message: option.description!,
                          child: Icon(Icons.help),
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: ThemeUtility.getThemeEnumByContext() ==
                                    Themes.Dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        );
                      } else {
                        return SizedBox();
                      }
                    }),
                  );

                  return _optionWidget;
                });
          }),
          StatefulBuilder(builder: (context, setPageState) {
            return PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pageController,
                itemCount: optionWidgets.call(setPageState).length,
                itemBuilder: (context, int Index) {
                  selectedIndex = Index;
                  return optionWidgets.call(setPageState)[Index];
                });
          })
        ],
        gripSize: 3,
        controller: SplitViewController(weights: weights),
        viewMode: SplitViewMode.Horizontal);
  }
}

class OptionPage extends StatefulWidget {
  final Widget mainWidget;
  final List<Widget> actions;

  OptionPage({
    Key? key,
    required this.mainWidget,
    required this.actions,
  }) : super(key: key);

  @override
  State<OptionPage> createState() =>
      _OptionPageState(mainWidget: mainWidget, actions: actions);
}

class _OptionPageState extends State<OptionPage> {
  final Widget mainWidget;
  final List<Widget> actions;

  _OptionPageState({
    required this.mainWidget,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SplitView(
      children: [
        mainWidget,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions,
        )
      ],
      viewMode: SplitViewMode.Vertical,
      gripSize: 0,
      controller: SplitViewController(
          weights: [0.95], limits: [WeightLimit(max: 0.95, min: 0.95)]),
    );
  }
}

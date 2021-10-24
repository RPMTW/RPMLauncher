// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:split_view/split_view.dart';

class OptionsView extends StatefulWidget {
  final List<Widget> Function(StateSetter) optionWidgets;
  final ViewOptions Function() options;
  final List<double?>? weights;
  final double gripSize;

  const OptionsView({
    Key? key,
    required this.optionWidgets,
    required this.options,
    required this.weights,
    required this.gripSize,
  }) : super(key: key);

  @override
  State<OptionsView> createState() => _OptionsViewState();
}

class _OptionsViewState extends State<OptionsView> {
  final PageController _pageController = PageController(initialPage: 0);
  int selectedIndex = 0;

  Future<void> _animateToPage(int index) async {
    int page = _pageController.page!.toInt();
    if (((page - index == 1) || page - index == -1)) {
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
                itemCount: widget.options.call().length,
                itemBuilder: (context, index) {
                  ViewOption option = widget.options.call().options[index];
                  late Widget _optionWidget;

                  if (option.empty) {
                    _optionWidget = SizedBox.shrink();
                  } else {
                    _optionWidget = ListTile(
                      title: Text(option.title!),
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
                                      Themes.dark
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          );
                        } else {
                          return SizedBox();
                        }
                      }),
                    );
                  }

                  return _optionWidget;
                });
          }),
          StatefulBuilder(builder: (context, setPageState) {
            return PageView(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              children: widget.optionWidgets.call(setPageState),
            );
          })
        ],
        gripSize: 3,
        controller: SplitViewController(weights: widget.weights),
        viewMode: SplitViewMode.Horizontal);
  }
}

class OptionPage extends StatefulWidget {
  final Widget mainWidget;
  final List<Widget> actions;

  const OptionPage({
    Key? key,
    required this.mainWidget,
    required this.actions,
  }) : super(key: key);

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  @override
  Widget build(BuildContext context) {
    return SplitView(
      children: [
        widget.mainWidget,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: widget.actions,
        )
      ],
      viewMode: SplitViewMode.Vertical,
      gripSize: 0,
      controller: SplitViewController(
          weights: [0.92], limits: [WeightLimit(max: 0.92, min: 0.92)]),
    );
  }
}

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:split_view/split_view.dart';

class OptionsView extends StatefulWidget {
  final List<Widget> optionWidgets;
  final ViewOptions options;
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
  final ViewOptions options;
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
                  ViewOption option = options.options[index];
                  Widget _optionWidget = ListTile(
                    title: Text(option.title),
                    leading: option.icon,
                    onTap: () async {
                      selectedIndex = index;
                      _setState(() {});
                      await _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    tileColor: selectedIndex == index
                        ? Colors.white12
                        : Theme.of(context).scaffoldBackgroundColor,
                  );

                  if (option.description != null) {
                    _optionWidget = Tooltip(
                      message: option.description!,
                      child: _optionWidget,
                      textStyle: TextStyle(
                        fontSize: 12,
                        color:
                            ThemeUtility.getThemeEnumByContext() == Themes.Dark
                                ? Colors.black
                                : Colors.white,
                      ),
                    );
                  }

                  return _optionWidget;
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

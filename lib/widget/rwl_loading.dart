import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/I18n.dart';

class RWLLoading extends StatefulWidget {
  final bool animations;
  final bool logo;

  const RWLLoading({
    Key? key,
    this.animations = false,
    this.logo = false,
  }) : super(key: key);

  @override
  State<RWLLoading> createState() => _RWLLoadingState();
}

class _RWLLoadingState extends State<RWLLoading> {
  bool get animations => widget.animations;
  bool get logo => widget.logo;

  double _widgetOpacity = 0;

  List<String> tips = [
    'rpmlauncher.tips.1',
    'rpmlauncher.tips.2',
    'rpmlauncher.tips.3',
  ];

  @override
  void initState() {
    if (animations) {
      Future.delayed(const Duration(milliseconds: 400)).whenComplete(() => {
            if (mounted)
              {
                setState(() {
                  _widgetOpacity = 1;
                })
              }
          });
    }

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget wdiget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            if (logo) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Logo.png', scale: 0.9),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              );
            } else {
              return const SizedBox();
            }
          }),
          logo
              ? SizedBox(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 45,
                  child: const LinearProgressIndicator())
              : const CircularProgressIndicator(),
          Builder(builder: (context) {
            if (logo) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Text(I18n.format('homepage.loading'),
                      style: const TextStyle(
                          fontSize: 35, color: Colors.lightBlue)),
                  const SizedBox(
                    height: 10,
                  ),
                  I18nText('rpmlauncher.tips.title',
                      style: const TextStyle(
                          fontSize: 15, fontStyle: FontStyle.italic)),
                  I18nText(tips.elementAt(Random().nextInt(tips.length)),
                      style: const TextStyle(fontSize: 20)),
                ],
              );
            } else {
              return const SizedBox();
            }
          }),
        ],
      ),
    );

    if (animations) {
      wdiget = AnimatedOpacity(
          opacity: _widgetOpacity,
          duration: const Duration(milliseconds: 700),
          child: wdiget);
    }
    return wdiget;
  }
}

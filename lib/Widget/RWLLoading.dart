// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

class RWLLoading extends StatefulWidget {
  final bool Animations;
  final bool Logo;

  RWLLoading({
    Key? key,
    this.Animations = false,
    this.Logo = false,
  }) : super(key: key);

  @override
  State<RWLLoading> createState() =>
      _RWLLoadingState(Animations: Animations, Logo: Logo);
}

class _RWLLoadingState extends State<RWLLoading> {
  final bool Animations;
  final bool Logo;

  _RWLLoadingState({
    required this.Animations,
    required this.Logo,
  });

  double _WidgetOpacity = 0;

  @override
  void initState() {
    if (Animations) {
      Future.delayed(Duration(milliseconds: 400)).then((value) => {
            setState(() {
              _WidgetOpacity = 1;
            })
          });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget _wdiget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            if (Logo) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("images/Logo.png", scale: 0.9),
                  SizedBox(
                    height: 10,
                  ),
                ],
              );
            } else {
              return SizedBox();
            }
          }),
          Logo
              ? Container(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 45,
                  child: LinearProgressIndicator())
              : CircularProgressIndicator(),
          SizedBox(
            height: Logo ? 10 : 1,
          ),
          Text(i18n.format('homepage.loading'),
              style: Logo ? TextStyle(fontSize: 35) : TextStyle(fontSize: 0))
        ],
      ),
    );

    if (Animations) {
      _wdiget = AnimatedOpacity(
          opacity: _WidgetOpacity,
          duration: Duration(milliseconds: 700),
          child: _wdiget);
    }
    return _wdiget;
  }
}

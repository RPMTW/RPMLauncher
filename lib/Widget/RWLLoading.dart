import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

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

  @override
  void initState() {
    if (animations) {
      Future.delayed(Duration(milliseconds: 400)).then((value) => {
            setState(() {
              _widgetOpacity = 1;
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
            if (logo) {
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
          logo
              ? SizedBox(
                  width: MediaQuery.of(context).size.width / 5,
                  height: MediaQuery.of(context).size.height / 45,
                  child: LinearProgressIndicator())
              : CircularProgressIndicator(),
          SizedBox(
            height: logo ? 10 : 1,
          ),
          Text(I18n.format('homepage.loading'),
              style: logo ? TextStyle(fontSize: 35) : TextStyle(fontSize: 0))
        ],
      ),
    );

    if (animations) {
      _wdiget = AnimatedOpacity(
          opacity: _widgetOpacity,
          duration: Duration(milliseconds: 700),
          child: _wdiget);
    }
    return _wdiget;
  }
}

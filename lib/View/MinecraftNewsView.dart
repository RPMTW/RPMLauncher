import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/MinecraftNews.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RPMNetworkImage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MinecraftNewsView extends StatefulWidget {
  final MinecraftNews news;

  const MinecraftNewsView({
    required this.news,
    Key? key,
  }) : super(key: key);

  @override
  State<MinecraftNewsView> createState() => _MinecraftNewsViewState();
}

class _MinecraftNewsViewState extends State<MinecraftNewsView> {
  late PageController newsPageController;
  int index = 0;
  MinecraftNew get _new => widget.news[index];

  @override
  void initState() {
    newsPageController = PageController(keepPage: true);
    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        index = index == widget.news.length ? 0 : index + 1;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 30,
        ),
        GridTile(
          child: Tooltip(
            message: "查看此新聞",
            child: InkWell(
              onTap: () => Uttily.openUrl(_new.link),
              child: Column(
                children: [
                  SizedBox(
                      width: 1024,
                      height: 438,
                      child: RPMNetworkImage(src: _new.imageUri)),
                  Text(_new.title, textAlign: TextAlign.center),
                  Text(
                    _new.description,
                  )
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        AnimatedSmoothIndicator(
          activeIndex: index,
          count: widget.news.length,
          onDotClicked: (_) {
            setState(() {
              index = _;
            });
          },
        )
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/MinecraftNews.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RPMNetworkImage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:split_view/split_view.dart';

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

  @override
  void initState() {
    newsPageController = PageController(keepPage: true);
    Timer.periodic(Duration(seconds: 5), (timer) {
      try {
        setState(() {
          index = index == (widget.news.length - 1) ? 0 : index + 1;
        });
      } catch (e) {}
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SplitView(
      viewMode: SplitViewMode.Vertical,
      gripSize: 2,
      controller: SplitViewController(
          limits: [WeightLimit(max: 0.3, min: 0.3)], weights: [0.3, 0.7]),
      children: [
        ListView(
          shrinkWrap: true,
          controller: ScrollController(),
          children: [
            SizedBox(
              height: 30,
            ),
            Builder(builder: (context) {
              MinecraftNew _new = widget.news[index];
              return Column(
                children: [
                  SizedBox(
                      width: 150,
                      height: 150,
                      child: RPMNetworkImage(src: _new.imageUri)),
                  Text(_new.title, textAlign: TextAlign.center),
                ],
              );
            }),
            SizedBox(
              height: 10,
            ),
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: index,
                count: widget.news.length,
              ),
            ),
          ],
        ),
        ListView.builder(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: widget.news.length,
            itemBuilder: (context, _index) {
              MinecraftNew _new = widget.news[_index];
              return ListTile(
                onTap: () => Uttily.openUrl(_new.link),
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: RPMNetworkImage(
                    src: _new.imageUri,
                    fit: BoxFit.contain,
                  ),
                ),
                title: Text(_new.title),
                subtitle: Text(_new.title),
                trailing: IconButton(
                  onPressed: () => Uttily.openUrl(_new.link),
                  icon: Icon(Icons.open_in_browser),
                ),
              );
            }),
      ],
    );
  }
}

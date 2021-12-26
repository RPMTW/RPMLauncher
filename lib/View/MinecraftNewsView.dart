import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
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

  @override
  void initState() {
    newsPageController = PageController(keepPage: true);
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          index = index == (widget.news.length - 1) ? 0 : index + 1;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 15,
            ),
            Builder(builder: (context) {
              MinecraftNew _new = widget.news[index];
              return InkWell(
                onTap: () => Uttily.openUri(_new.link),
                child: Column(
                  children: [
                    SizedBox(
                        width: 250,
                        height: 250,
                        child: RPMNetworkImage(src: _new.imageUri)),
                    Text(_new.title, textAlign: TextAlign.center),
                  ],
                ),
              );
            }),
            SizedBox(
              height: 10,
            ),
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: index,
                count: widget.news.length,
                onDotClicked: (index_) {
                  index=index_;
                  setState(() {

                  });
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
              controller: ScrollController(),
              itemCount: widget.news.length,
              itemBuilder: (context, _index) {
                MinecraftNew _new = widget.news[_index];
                return ListTile(
                  onTap: () => Uttily.openUri(_new.link),
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: RPMNetworkImage(
                      src: _new.imageUri,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(_new.title),
                  subtitle: Text(_new.description),
                  trailing: IconButton(
                    onPressed: () => Uttily.openUri(_new.link),
                    icon: Icon(Icons.open_in_browser),
                  ),
                );
              }),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/Game/MinecraftNews.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/RPMNetworkImage.dart';
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
    Timer.periodic(const Duration(seconds: 5), (timer) {
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
            const SizedBox(
              height: 15,
            ),
            Builder(builder: (context) {
              MinecraftNew news = widget.news[index];
              return InkWell(
                onTap: () => Util.openUri(news.link),
                child: Column(
                  children: [
                    SizedBox(
                        width: 250,
                        height: 250,
                        child: RPMNetworkImage(src: news.imageUri)),
                    Text(news.title, textAlign: TextAlign.center),
                  ],
                ),
              );
            }),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: index,
                count: widget.news.length,
                onDotClicked: (index_) {
                  index = index_;
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
              controller: ScrollController(),
              itemCount: widget.news.length,
              itemBuilder: (context, index) {
                MinecraftNew news = widget.news[index];
                return ListTile(
                  onTap: () => Util.openUri(news.link),
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: RPMNetworkImage(
                      src: news.imageUri,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(news.title),
                  subtitle: Text(news.description),
                  trailing: IconButton(
                    onPressed: () => Util.openUri(news.link),
                    icon: const Icon(Icons.open_in_browser),
                  ),
                );
              }),
        ),
      ],
    );
  }
}

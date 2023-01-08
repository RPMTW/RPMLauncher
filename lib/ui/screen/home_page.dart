import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/screen/collection_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_app_bar.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/background.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController controller;

  @override
  void initState() {
    controller = PageController(initialPage: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Background(),
        Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            context.theme.mainColor.withOpacity(0.95),
            Colors.transparent
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Blur(
            blur: 7,
            colorOpacity: 0,
            child: Container(),
          ),
        ),
        SafeArea(
            child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              RPMLAppBar(
                onIndexChanged: (index) {
                  controller.animateToPage(index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: PageView.builder(
                      controller: controller,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        switch (index) {
                          case 1:
                            return const CollectionPage();
                          default:
                            return const CollectionPage();
                        }
                      }),
                ),
              )
            ],
          ),
        ))
      ],
    );
  }
}

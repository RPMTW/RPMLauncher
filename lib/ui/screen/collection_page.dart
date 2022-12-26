import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/widget/rpml_app_bar.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/background.dart';

class CollectionPage extends StatefulWidget {
  static const String route = '/collection';

  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Background(
          child: Container(),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Blur(
            blur: 18,
            colorOpacity: 0.8,
            blurColor: const Color(0XFF1F1F1F),
            child: Container(),
          ),
        ),
        SafeArea(
            child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _buildTitle(context),
            ],
          ),
        ))
      ],
    );
  }

  Align _buildTitle(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: ClipRRect(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
          child: RPMLAppBar()),
    );
  }
}

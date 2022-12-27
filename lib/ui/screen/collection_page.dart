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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildCategory(),
                  ],
                ),
              )
            ],
          ),
        ))
      ],
    );
  }

  Widget _buildCategory() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        constraints: const BoxConstraints(minWidth: 300, maxHeight: 500),
        child: Blur(
          blur: 100,
          blurColor: Colors.transparent,
          colorOpacity: 0,
          overlay: Column(
            children: const [
              Text(
                '分類',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          child: Container(color: const Color(0XFF2F2F2F).withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
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

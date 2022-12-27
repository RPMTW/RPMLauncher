import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
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
            colorOpacity: 0.6,
            blurColor: const Color(0XFF000000),
            child: Container(),
          ),
        ),
        SafeArea(
            child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _buildTitle(),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 80),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildCategory(),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFavorite(),
                          const SizedBox(height: 15),
                          _buildCollections(),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ))
      ],
    );
  }

  Widget _buildCollections() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, minHeight: 500),
      child: Blur(
        blur: 20,
        blurColor: const Color(0XFF2F2F2F),
        colorOpacity: 0.5,
        borderRadius: BorderRadius.circular(10),
        alignment: Alignment.topLeft,
        overlay: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: const [Text('所有收藏')],
          ),
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildFavorite() {
    return Row(
      children: [
        const Icon(Icons.favorite, color: Colors.red, size: 35),
        const SizedBox(width: 6),
        Text('我的最愛',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: context.theme.textColor))
      ],
    );
  }

  Widget _buildCategory() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Blur(
        blur: 20,
        blurColor: const Color(0XFF2F2F2F),
        colorOpacity: 0.5,
        borderRadius: BorderRadius.circular(10),
        alignment: Alignment.topLeft,
        overlay: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                '分類',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.theme.textColor),
              ),
            ],
          ),
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildTitle() {
    return const ClipRRect(
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        child: RPMLAppBar());
  }
}

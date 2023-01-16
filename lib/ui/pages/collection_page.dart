import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/pages/collection/choose_loader_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';

class CollectionPage extends StatefulWidget {
  static const String route = 'collection';
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.interests_rounded, size: 50),
            SizedBox(width: 12),
            Text('收藏庫', style: TextStyle(fontSize: 42)),
          ],
        ),
        // TODO: category
        const SizedBox(height: 50),
        Expanded(child: _buildCollections()),
        _buildToolBar(),
      ],
    );
  }

  Widget _buildCollections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Blur(
        blur: 15,
        blurColor: context.theme.mainColor,
        colorOpacity: 0.3,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        overlay: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          child: Column(),
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildToolBar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 65),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: context.theme.mainColor.withOpacity(0.3),
              blurRadius: 50,
              blurStyle: BlurStyle.outer,
            )
          ],
          borderRadius: BorderRadius.circular(13),
          border: Border.all(width: 2, color: context.theme.primaryColor)),
      child: Blur(
          blur: 15,
          blurColor: context.theme.mainColor,
          colorOpacity: 0.3,
          borderRadius: BorderRadius.circular(10),
          overlay: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 12,
                    children: [
                      RPMLButton(
                        label: '選取多個',
                        isOutline: true,
                        icon: const Icon(Icons.done_all),
                        onPressed: () {},
                      ),
                      RPMLButton(
                        label: '選取全部',
                        isOutline: true,
                        icon: const Icon(Icons.select_all),
                        onPressed: () {},
                      )
                    ],
                  )
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 65,
                    child: ElevatedButton.icon(
                      label: Text('建立自訂收藏',
                          style: TextStyle(
                              color: context.theme.textColor, fontSize: 18)),
                      icon: Icon(Icons.loupe,
                          color: context.theme.textColor, size: 30),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primaryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(50),
                            right: Radius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) => const ChooseLoaderPage());
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          child: Container()),
    );
  }
}

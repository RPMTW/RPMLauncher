import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/route/slide_route.dart';
import 'package:rpmlauncher/ui/pages/collection/choose_loader_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/blur_block.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_tool_bar.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      initialRoute: _CollectionMainPage.route,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case ChooseLoaderPage.route:
            return SlideRoute(builder: (context) => const ChooseLoaderPage());
          case _CollectionMainPage.route:
            return MaterialPageRoute(
                builder: (context) => const _CollectionMainPage());
          default:
            throw Exception('Unknown route: ${settings.name}');
        }
      },
    );
  }
}

class _CollectionMainPage extends StatefulWidget {
  static const String route = 'collection';
  const _CollectionMainPage();

  @override
  State<_CollectionMainPage> createState() => __CollectionMainPageState();
}

class __CollectionMainPageState extends State<_CollectionMainPage> {
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
        RPMLToolBar(
          label: '建立自訂收藏',
          onPressed: () {
            Navigator.pushNamed(context, ChooseLoaderPage.route);
          },
          icon: const Icon(Icons.loupe_rounded),
          actions: [
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
        ),
      ],
    );
  }

  Widget _buildCollections() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BlurBlock(child: Column()),
    );
  }
}

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/ui/pages/collection/choose_version_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_dialog.dart';

class ChooseLoaderPage extends StatefulWidget {
  static const String route = 'choose_loader';
  const ChooseLoaderPage({super.key});

  @override
  State<ChooseLoaderPage> createState() => _ChooseLoaderPageState();
}

class _ChooseLoaderPageState extends State<ChooseLoaderPage>
    with SingleTickerProviderStateMixin {
  GameLoader? selected;
  late final AnimationController _animationController;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _animation = _animationController.drive(IntTween(begin: 1000, end: 7000));
    const spring = SpringDescription(
      mass: 1,
      stiffness: 320,
      damping: 40,
    );
    final simulation = SpringSimulation(spring, 0, 1, 0);
    _animationController.animateWith(simulation);
    _animation.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RPMLDialog(
      title: '載入器類型',
      icon: Icon(Icons.offline_bolt_rounded, color: context.theme.primaryColor),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLoader('原版', GameLoader.vanilla),
            _buildLoader('Forge', GameLoader.forge),
            _buildLoader('Fabric', GameLoader.fabric),
            _buildLoader('Quilt', GameLoader.quilt)
          ],
        ),
      ),
    );
  }

  Widget _buildLoader(String name, GameLoader loader) {
    final bool isSelected = selected == loader;
    final bool showContent = selected == null || isSelected;

    final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          context.theme.mainColor.withOpacity(isSelected ? 0.21 : 0.3),
          context.theme.mainColor.withOpacity(isSelected ? 0.7 : 0.95)
        ]);

    return StatefulBuilder(builder: (context, setState) {
      return Expanded(
        flex: isSelected ? _animation.value : 1000,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () async {
              if (isSelected) {
                _animationController.reverse().whenComplete(() {
                  setState(() {
                    selected = null;
                  });
                });
              } else {
                _animationController.reset();
                _animationController.forward();
                setState(() {
                  selected = loader;
                });
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(loader.getBackgroundAssets()),
                        fit: BoxFit.cover)),
                child: Stack(
                  children: [
                    Blur(
                      colorOpacity: 0,
                      blur: showContent ? 2.5 : 10,
                      child: Container(
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                    if (showContent)
                      Builder(builder: (context) {
                        final selectedContent = Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: FittedBox(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.asset(loader.getIconAssets(),
                                          width: 85, height: 85),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FittedBox(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      RPMLButton(
                                        label: '選擇更多版本',
                                        isOutline: true,
                                        width: 150,
                                        height: 55,
                                        backgroundBlur: 5,
                                        labelType: RPMLButtonLabelType.text,
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              // We don't need another barrier
                                              barrierColor: Colors.transparent,
                                              builder: (context) =>
                                                  ChooseVersionPage(
                                                      loader: loader));
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      const RPMLButton(
                                        label: '安裝最新版',
                                        width: 200,
                                        height: 55,
                                        labelType: RPMLButtonLabelType.text,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );

                        final unselectedContent = Center(
                          child: FittedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.asset(loader.getIconAssets(),
                                      width: 50, height: 50),
                                ),
                                const SizedBox(height: 12),
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );

                        return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            transitionBuilder: (child, animation) {
                              return SlideTransition(
                                position: animation.drive(Tween<Offset>(
                                    begin: const Offset(0, 1),
                                    end: Offset.zero)),
                                child: child,
                              );
                            },
                            child: isSelected
                                ? selectedContent
                                : unselectedContent);
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

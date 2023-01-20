import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/route/slide_route.dart';
import 'package:rpmlauncher/ui/pages/collection/choose_version_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/view/row_scroll_view.dart';
import 'package:rpmlauncher/ui/widget/blur_block.dart';
import 'package:rpmlauncher/ui/widget/round_divider.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_tool_bar.dart';

class ChooseLoaderPage extends StatefulWidget {
  const ChooseLoaderPage({super.key});

  Future<void> show(BuildContext context) {
    return Navigator.push(context,
        SlideRoute(builder: (context) => this));
  }

  @override
  State<ChooseLoaderPage> createState() => _ChooseLoaderPageState();
}

class _ChooseLoaderPageState extends State<ChooseLoaderPage> {
  GameLoader? selected;
  bool firstShow = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.offline_bolt_rounded, size: 50),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('載入器類型', style: TextStyle(fontSize: 30)),
              Text('選擇用於建立您的收藏的載入器類型',
                  style: TextStyle(
                      color: context.theme.primaryColor, fontSize: 15))
            ])
          ],
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: BlurBlock(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Loader(
                        name: '原版',
                        loader: GameLoader.vanilla,
                        selected: selected,
                        onSelectedChange: (loader) {
                          setState(() {
                            selected = loader;
                            firstShow = false;
                          });
                        },
                        firstShow: firstShow),
                    _Loader(
                        name: 'Forge',
                        loader: GameLoader.forge,
                        selected: selected,
                        onSelectedChange: (loader) {
                          setState(() {
                            selected = loader;
                            firstShow = false;
                          });
                        },
                        firstShow: firstShow),
                    _Loader(
                        name: 'Fabric',
                        loader: GameLoader.fabric,
                        selected: selected,
                        onSelectedChange: (loader) {
                          setState(() {
                            selected = loader;
                            firstShow = false;
                          });
                        },
                        firstShow: firstShow),
                    _Loader(
                        name: 'Quilt',
                        loader: GameLoader.quilt,
                        selected: selected,
                        onSelectedChange: (loader) {
                          setState(() {
                            selected = loader;
                            firstShow = false;
                          });
                        },
                        firstShow: firstShow),
                  ],
                ),
              ),
            ),
          ),
        ),
        const RPMLToolBar(),
      ],
    );
  }
}

class _Loader extends StatefulWidget {
  final String name;
  final GameLoader loader;
  final GameLoader? selected;
  final ValueChanged<GameLoader?> onSelectedChange;
  final bool firstShow;

  const _Loader(
      {required this.name,
      required this.loader,
      required this.selected,
      required this.onSelectedChange,
      required this.firstShow});

  @override
  State<_Loader> createState() => __LoaderState();
}

class __LoaderState extends State<_Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _animation = _animationController.drive(IntTween(begin: 1500, end: 7000));
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
    final isSelected = widget.selected == widget.loader;
    final bool showContent = widget.selected == null || isSelected;

    final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          context.theme.mainColor.withOpacity(isSelected ? 0.21 : 0.3),
          context.theme.mainColor.withOpacity(isSelected ? 0.7 : 0.95)
        ]);

    final content = Stack(
      // We use a key to make sure the animation is triggered.
      key: ValueKey(_animation.value.hashCode + widget.selected.hashCode),
      children: [
        Center(
          child: _buildBoxShadow(
            color: isSelected
                ? context.theme.primaryColor.withOpacity(0.8)
                : context.theme.mainColor.withOpacity(0.6),
            blur: isSelected ? 60 : 30,
            offset: isSelected ? Offset.zero : const Offset(5, 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(widget.loader.getIconAssets(),
                  width: isSelected ? 150 : 100,
                  height: isSelected ? 150 : 100),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BlurBlock(
            constraints: BoxConstraints(maxHeight: isSelected ? 105 : 85),
            colorOpacity: 0.5,
            child: Builder(builder: (context) {
              if (isSelected) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(25),
                          child: SizedBox(
                              height: 80,
                              child: _buildBoxShadow(
                                child: RoundDivider(
                                    size: 5, color: context.theme.primaryColor),
                                blur: 10,
                              )),
                        ),
                        _buildBoxShadow(
                            child: Text(widget.name,
                                style: const TextStyle(
                                    fontSize: 35, fontWeight: FontWeight.w600)),
                            blur: 10,
                            color: context.theme.primaryColor.withOpacity(0.15),
                            offset: const Offset(5, 5)),
                      ],
                    ),
                    Expanded(
                      child: RowScrollView(
                        alignment: Alignment.centerRight,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildBoxShadow(
                                      child: const RPMLButton(
                                        label: '安裝最新版',
                                        width: 200,
                                        height: 80,
                                        labelType: RPMLButtonLabelType.text,
                                      ),
                                      blur: 15),
                                  const SizedBox(width: 10),
                                  RPMLButton(
                                    label: '選擇更多版本',
                                    isOutline: true,
                                    width: 160,
                                    height: 80,
                                    backgroundBlur: 5,
                                    labelType: RPMLButtonLabelType.text,
                                    onPressed: () {
                                      ChooseVersionPage(loader: widget.loader)
                                          .show(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              } else {
                return Text(widget.name,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w600));
              }
            }),
          ),
        ),
      ],
    );

    return Expanded(
      flex: isSelected ? _animation.value : 1500,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () async {
            if (isSelected) {
              _animationController.reverse().whenComplete(() {
                widget.onSelectedChange(null);
              });
            } else {
              _animationController.reset();
              _animationController.forward();
              widget.onSelectedChange(widget.loader);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(widget.loader.getBackgroundAssets()),
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
                  if (!showContent)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(widget.loader.getIconAssets(),
                            width: 75, height: 75),
                      ),
                    ),
                  if (showContent)
                    AnimatedSwitcher(
                        duration:
                            Duration(milliseconds: widget.firstShow ? 0 : 300),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                  axis: Axis.horizontal,
                                  axisAlignment: -1.0,
                                  sizeFactor: animation,
                                  child: child));
                        },
                        child: content)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxShadow(
      {required Widget child,
      required double blur,
      Color? color,
      Offset offset = Offset.zero}) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            color: color ?? context.theme.primaryColor.withOpacity(0.4),
            blurRadius: blur,
            offset: offset)
      ], borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}

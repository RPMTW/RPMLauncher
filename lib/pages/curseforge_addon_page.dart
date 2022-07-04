import 'package:rpmlauncher/mod/curseforge/curseforge_handler.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/view/RowScrollView.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class _CurseForgeAddonPageState extends State<CurseForgeAddonPage> {
  late TextEditingController searchController;
  late ScrollController scrollController;

  List<CurseForgeMod> oldAddonList = [];
  int index = 0;

  final List<CurseForgeSortField> sortItems = [
    CurseForgeSortField.featured,
    CurseForgeSortField.popularity,
    CurseForgeSortField.lastUpdated,
    CurseForgeSortField.name,
    CurseForgeSortField.author,
    CurseForgeSortField.totalDownloads
  ];
  CurseForgeSortField sortItem = CurseForgeSortField.popularity;

  @override
  void initState() {
    searchController = TextEditingController();
    scrollController = ScrollController();

    super.initState();

    scrollController.addListener(() {
      if ((scrollController.position.maxScrollExtent -
              scrollController.position.pixels) <
          50) {
        // if scroll to bottom
        index += 20;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Text(widget.title, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          RowScrollView(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.search),
                const SizedBox(width: 12),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: RPMTextField(
                        textAlign: TextAlign.center,
                        controller: searchController,
                        hintText: widget.searchHint,
                        onEditingComplete: () => cleanAllMods())),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepPurpleAccent)),
                  onPressed: () => cleanAllMods(),
                  child: Text(I18n.format('gui.search')),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    I18nText('edit.instance.mods.sort'),
                    DropdownButton<CurseForgeSortField>(
                      value: sortItem,
                      onChanged: (CurseForgeSortField? newValue) {
                        setState(() {
                          sortItem = newValue!;
                          cleanAllMods();
                        });
                      },
                      items: sortItems
                          .map<DropdownMenuItem<CurseForgeSortField>>(
                              (CurseForgeSortField value) {
                        return DropdownMenuItem<CurseForgeSortField>(
                          value: value,
                          child: I18nText(
                            'edit.instance.mods.sort.curseforge.${value.name}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                ...?widget.fitterOptions?.call(cleanAllMods)
              ],
            ),
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder<List<CurseForgeMod>>(
            future: Future.sync(() async => sortMods(await widget.getModList(
                searchController.text.isEmpty ? null : searchController.text,
                index,
                sortItem))),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty &&
                    snapshot.connectionState == ConnectionState.done) {
                  return I18nText(widget.notFound,
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                } else if (snapshot.connectionState != ConnectionState.done &&
                    snapshot.data!.length < 20) {
                  return const Center(child: RWLLoading());
                }

                return ListView.builder(
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    CurseForgeMod mod = snapshot.data![index];
                    String modName = mod.name;
                    String modDescription = mod.summary;
                    int curseID = mod.id;
                    String pageUrl = mod.links.websiteUrl;

                    return ListTile(
                      leading: CurseForgeHandler.getAddonIconWidget(mod.logo),
                      title: Text(modName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              Util.openUri(pageUrl);
                            },
                            icon: const Icon(Icons.open_in_browser),
                            tooltip:
                                I18n.format('edit.instance.mods.page.open'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                              onPressed: () => widget.onInstall(curseID, mod),
                              child: Text(I18n.format('gui.install'))),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: I18nText(widget.tapNameKey,
                                  args: {"name": modName},
                                  textAlign: TextAlign.center),
                              content: I18nText(widget.tapDescriptionKey,
                                  args: {"description": modDescription},
                                  textAlign: TextAlign.center),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return const Center(child: RWLLoading());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close_sharp),
          tooltip: I18n.format('gui.close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  /// filter the same curseforge mod id
  List<CurseForgeMod> sortMods(List<CurseForgeMod> sources) {
    final List<CurseForgeMod> mods = oldAddonList;

    sources.forEach((mod) {
      if (!(oldAddonList.any((_) => _.id == mod.id))) {
        mods.add(mod);
      }
    });

    oldAddonList = mods;

    return mods;
  }

  void cleanAllMods() {
    setState(() {
      index = 0;
      oldAddonList.clear();
    });
  }
}

class CurseForgeAddonPage extends StatefulWidget {
  final String title;
  final String search;
  final String searchHint;
  final String notFound;
  final String tapNameKey;
  final String tapDescriptionKey;

  final Future<List<CurseForgeMod>> Function(
      String? fitter, int index, CurseForgeSortField sort) getModList;
  final void Function(int curseID, CurseForgeMod mod) onInstall;

  final List<Widget> Function(VoidCallback cleanAllMods)? fitterOptions;

  const CurseForgeAddonPage(
      {Key? key,
      required this.title,
      required this.search,
      required this.searchHint,
      required this.notFound,
      required this.tapNameKey,
      required this.tapDescriptionKey,
      required this.getModList,
      required this.onInstall,
      this.fitterOptions})
      : super(key: key);

  @override
  State<CurseForgeAddonPage> createState() => _CurseForgeAddonPageState();
}

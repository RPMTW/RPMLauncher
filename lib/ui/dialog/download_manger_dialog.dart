import 'dart:async';

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/task/task_manager.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/round_divider.dart';
import 'package:uuid/uuid.dart';

class DownloadMangerDialog extends StatefulWidget {
  const DownloadMangerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
        context: context,
        transitionDuration: const Duration(milliseconds: 400),
        barrierDismissible: true,
        barrierLabel: 'download_manager_dialog${const Uuid().v4()}',
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
              child: const DownloadMangerDialog());
        });
  }

  @override
  State<DownloadMangerDialog> createState() => _DownloadMangerDialogState();
}

class _DownloadMangerDialogState extends State<DownloadMangerDialog> {
  @override
  void initState() {
    super.initState();

    taskManager.addListener(() {
      if (mounted) {
        setState(() {});
      } else {
        taskManager.removeListener(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      alignment: Alignment.topLeft,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.theme.backgroundColor,
                      context.theme.backgroundColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3), blurRadius: 25),
                  ],
                ),
                child: Blur(
                  blur: 3,
                  colorOpacity: 0,
                  overlay: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              const Icon(Icons.downloading_rounded, size: 50),
                              const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: RoundDivider(
                                      size: 1.5, color: Color(0XFF4F4F4F))),
                              Text(
                                '下載管理',
                                style: TextStyle(
                                    fontSize: 23,
                                    color: context.theme.textColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(taskManager.receivedBytes.toString()),
                        _TaskList(getTasks: () => taskManager.getAll())
                      ],
                    ),
                  ),
                  child: Container(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    color: context.theme.dialogBackgroundColor,
                    width: 90,
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            tooltip: '下載設定',
                            onPressed: () {},
                            icon: Icon(Icons.tune_rounded,
                                color: context.theme.primaryColor)),
                        IconButton(
                            tooltip: I18n.format('gui.close'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.menu_open_rounded))
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatefulWidget {
  final List<Task> Function() getTasks;
  const _TaskList({required this.getTasks});

  @override
  State<_TaskList> createState() => __TaskListState();
}

class __TaskListState extends State<_TaskList> {
  @override
  Widget build(BuildContext context) {
    final tasks = widget.getTasks();

    return Expanded(
      child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return _TaskTile(
              task: task,
              onRemove: () {
                taskManager.remove(task);
                setState(() {});
              },
            );
          }),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onRemove;
  const _TaskTile({required this.task, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: context.theme.dialogBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                        fontSize: 17,
                        color: context.theme.textColor,
                        fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    onPressed: () {
                      task.cancel();
                      onRemove?.call();
                    },
                    iconSize: 20,
                    tooltip: I18n.format('gui.cancel'),
                    icon: const Icon(Icons.cancel, color: Color(0XFF4F4F4F)),
                  )
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 0,
                    end: task.totalProgress,
                  ),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      color: context.theme.primaryColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/FileDeleteError.dart';

class DeleteFileWidget extends StatelessWidget {
  final FileSystemEntity fileSystemEntity;
  final String message;
  final String tooltip;
  final Function? onDeleted;

  const DeleteFileWidget({
    required this.message,
    required this.tooltip,
    required this.fileSystemEntity,
    this.onDeleted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete),
      tooltip: tooltip,
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: Text(I18n.format("gui.tips.info")),
                  content: Text(message),
                  actions: [
                    TextButton(
                      child: Text(I18n.format("gui.cancel")),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                        child: Text(I18n.format("gui.confirm")),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (fileSystemEntity.existsSync()) {
                            try {
                              fileSystemEntity.deleteSync(recursive: true);
                            } on FileSystemException {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const FileDeleteError());
                            }
                          }

                          if (onDeleted != null) {
                            onDeleted!();
                          }
                        }),
                  ]);
            });
      },
    );
  }
}

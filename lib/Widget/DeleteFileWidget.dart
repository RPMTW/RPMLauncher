import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class DeleteFileWidget extends StatelessWidget {
  final FileSystemEntity fileSystemEntity;
  final String message;
  final String tooltip;
  final Function? onDelete;

  const DeleteFileWidget({
    required this.message,
    required this.tooltip,
    required this.fileSystemEntity,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.delete),
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
                            fileSystemEntity.deleteSync(recursive: true);
                          }

                          if (onDelete != null) {
                            onDelete!();
                          }
                        }),
                  ]);
            });
      },
    );
  }
}

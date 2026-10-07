import 'package:flutter/material.dart';

import '../../services/group_service.dart';
import '../group_picker.dart';
import '../qio_card.dart';

class QueueGroupTile extends StatelessWidget {
  const QueueGroupTile({
    super.key,
    required this.queueId,
    required this.groupId,
  });

  final String queueId;
  final String? groupId;

  Future<void> _change(BuildContext context, String? id) async {
    try {
      await GroupService.instance.setQueueGroup(queueId, id);
    } on Exception catch (e) {
      if (context.mounted) showGroupError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QioCard(
      child: GroupPicker(
        value: groupId,
        onChanged: (id) => _change(context, id),
      ),
    );
  }
}

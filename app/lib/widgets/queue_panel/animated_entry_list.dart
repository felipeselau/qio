import 'package:flutter/material.dart';

import '../../models/queue_entry.dart';

class AnimatedEntryList extends StatefulWidget {
  const AnimatedEntryList({
    super.key,
    required this.entries,
    required this.itemBuilder,
  });

  final List<QueueEntry> entries;
  final Widget Function(BuildContext context, QueueEntry entry) itemBuilder;

  @override
  State<AnimatedEntryList> createState() => _AnimatedEntryListState();
}

class _AnimatedEntryListState extends State<AnimatedEntryList> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<QueueEntry> _items = List.of(widget.entries);

  @override
  void didUpdateWidget(covariant AnimatedEntryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.entries;
    final incomingIds = {for (final e in incoming) e.id};

    for (var i = _items.length - 1; i >= 0; i--) {
      if (!incomingIds.contains(_items[i].id)) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _transition(
            animation,
            widget.itemBuilder(context, removed),
            fromRight: true,
          ),
          duration: const Duration(milliseconds: 220),
        );
      }
    }

    for (var i = 0; i < incoming.length; i++) {
      final entry = incoming[i];
      final at = _items.indexWhere((e) => e.id == entry.id);
      if (at == -1) {
        final index = i.clamp(0, _items.length);
        _items.insert(index, entry);
        _listKey.currentState?.insertItem(
          index,
          duration: const Duration(milliseconds: 250),
        );
      } else {
        _items[at] = entry;
      }
    }

    final sameOrder =
        _items.length == incoming.length &&
        [for (final e in _items) e.id].join() ==
            [for (final e in incoming) e.id].join();
    if (!sameOrder) {
      final byId = {for (final e in incoming) e.id: e};
      _items = [
        for (final e in incoming)
          if (byId.containsKey(e.id)) e,
      ];
    }
  }

  Widget _transition(
    Animation<double> animation,
    Widget child, {
    bool fromRight = false,
  }) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(fromRight ? 0.2 : -0.1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();
        return _transition(
          animation,
          widget.itemBuilder(context, _items[index]),
        );
      },
    );
  }
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'Q';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String formatMemberSince(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString().padLeft(4, '0');
  return '$dd/$mm/$yyyy';
}

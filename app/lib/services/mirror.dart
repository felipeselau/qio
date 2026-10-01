bool mirrorNeedsRepair(
  Map<dynamic, dynamic>? owner,
  Map<dynamic, dynamic>? meta,
  String uid,
) {
  if (owner == null) return true;
  if (owner['ownerUid'] != uid) return true;
  if (meta == null) return true;
  return false;
}

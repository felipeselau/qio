Future<bool> resolveAnonymizePhone({
  bool? known,
  required Future<bool> Function() read,
}) async {
  if (known != null) return known;
  try {
    return await read();
  } on Exception {
    return true;
  }
}

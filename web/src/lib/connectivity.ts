export function isEffectivelyOnline(
  browserOnline: boolean,
  rtdbConnected: boolean | null,
  everConnected: boolean,
): boolean {
  if (!browserOnline) return false;
  if (rtdbConnected === false && everConnected) return false;
  return true;
}

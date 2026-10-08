export function formatPhone(raw: string): string {
  const digits = raw.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 2) return digits;
  if (digits.length <= 6) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`;
  if (digits.length <= 10)
    return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`;
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`;
}

export function isValidPhone(phone: string): boolean {
  return /^\(\d{2}\) \d{4,5}-\d{4}$/.test(phone);
}

export function elapsedSince(startMs: number, nowMs: number): number {
  return Math.max(0, Math.floor((nowMs - startMs) / 1000));
}

export function formatElapsed(totalSeconds: number): string {
  const safe = Math.max(0, Math.floor(totalSeconds));
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

export function effectiveAvgMin(
  auto: number | null | undefined,
  manual: number | null | undefined,
): number {
  const valid = (n: number | null | undefined): n is number =>
    typeof n === 'number' && Number.isFinite(n) && n > 0;
  if (valid(auto)) return auto;
  if (valid(manual)) return manual;
  return 10;
}

export type WaitRange = { min: number; max: number };

export function waitRange(position: number, avgMin: number): WaitRange | null {
  if (!Number.isFinite(position) || !Number.isFinite(avgMin) || position < 1 || avgMin <= 0) {
    return null;
  }
  const base = position * avgMin;
  const min = Math.max(1, Math.round(base * 0.7));
  const max = Math.max(min + 1, Math.round(base * 1.4));
  return { min, max };
}

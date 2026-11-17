const N = 25;

function finder(x: number, y: number, cx: number, cy: number) {
  const dx = x - cx;
  const dy = y - cy;
  if (dx < -1 || dx > 7 || dy < -1 || dy > 7) return null;
  if (dx < 0 || dx > 6 || dy < 0 || dy > 6) return false;
  const ring = Math.max(Math.abs(dx - 3), Math.abs(dy - 3));
  return ring === 3 || ring <= 1;
}

export function qrPath(): string {
  let seed = 7;
  const rnd = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };
  let d = '';
  for (let y = 0; y < N; y++) {
    for (let x = 0; x < N; x++) {
      const f =
        finder(x, y, 0, 0) ?? finder(x, y, N - 7, 0) ?? finder(x, y, 0, N - 7);
      const on = f === null ? rnd() > 0.52 : f;
      if (on) d += `M${x} ${y}h1v1h-1z`;
    }
  }
  return d;
}

export const QR_SIZE = N;

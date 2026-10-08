type Sentinel = { release: () => Promise<void> };
type WakeLockApi = { request: (type: 'screen') => Promise<Sentinel> };

export function holdWakeLock(): () => void {
  const api = (navigator as unknown as { wakeLock?: WakeLockApi }).wakeLock;
  if (!api) return () => {};
  let sentinel: Sentinel | null = null;
  let stopped = false;

  const acquire = () => {
    if (stopped || sentinel || document.visibilityState !== 'visible') return;
    api
      .request('screen')
      .then((lock) => {
        if (stopped) {
          lock.release().catch(() => {});
          return;
        }
        sentinel = lock;
        (lock as unknown as EventTarget).addEventListener?.('release', () => {
          if (sentinel === lock) sentinel = null;
        });
      })
      .catch(() => {});
  };

  const onVisibility = () => {
    if (document.visibilityState === 'visible') acquire();
  };

  document.addEventListener('visibilitychange', onVisibility);
  acquire();

  return () => {
    stopped = true;
    document.removeEventListener('visibilitychange', onVisibility);
    const current = sentinel;
    sentinel = null;
    current?.release().catch(() => {});
  };
}

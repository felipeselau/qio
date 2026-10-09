import { useEffect, useState } from 'react';
import type { QueueMeta } from '../../lib/useQueue';

export default function QueueLogo({ meta }: { meta: QueueMeta | null }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    setFailed(false);
  }, [meta?.logoUrl]);
  if (!meta) return null;
  const initial = meta.name.trim().charAt(0).toUpperCase() || 'Q';
  if (meta.logoUrl && !failed) {
    return (
      <img
        className="queue-logo"
        src={meta.logoUrl}
        alt={meta.name}
        referrerPolicy="no-referrer"
        onError={() => setFailed(true)}
      />
    );
  }
  if (!meta.brandColor) return null;
  return (
    <div className="queue-logo queue-logo-fallback" aria-hidden="true">
      {initial}
    </div>
  );
}

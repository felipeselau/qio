import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { QueueMeta } from '../../lib/useQueue';
import { elapsedSince, formatElapsed } from '../../lib/format';
import { OfflineBanner } from './Banners';

function CalledTimer({ calledAt }: { calledAt: number | null }) {
  const { t } = useTranslation();
  const [startedAt] = useState(() => Date.now());
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, []);
  const seconds = elapsedSince(calledAt ?? startedAt, now);
  return (
    <p style={{ fontSize: 14, opacity: 0.9 }}>
      {t('queue.calledSince', { time: formatElapsed(seconds) })}
    </p>
  );
}

type Props = {
  meta: QueueMeta | null;
  ticket: number;
  calledAt: number | null;
  announce: string;
};

export default function CalledView({ meta, ticket, calledAt, announce }: Props) {
  const { t } = useTranslation();
  return (
    <div
      className="fade-in" key="called"
      style={{
        background: 'var(--success-strong)',
        flex: 1,
        minHeight: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 16,
        padding: 32,
        textAlign: 'center',
        color: 'var(--white)',
      }}
    >
      <OfflineBanner />
      <div className="sr-only" role="alert" aria-live="assertive">
        {announce}
      </div>
      <div
        style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}
      >
        <div style={{ fontSize: 72 }} aria-hidden="true">✓</div>
        <h1 data-autofocus tabIndex={-1} style={{ fontSize: 24, fontWeight: 700 }}>{t('queue.yourTurn')}</h1>
        {meta?.name && <p style={{ fontSize: 16, opacity: 0.95 }}>{meta.name}</p>}
        <p style={{ fontSize: 18, fontWeight: 600 }}>
          {t('queue.ticketNumber', { ticket })}
        </p>
        <p style={{ fontSize: 14, opacity: 0.9 }}>
          {t('queue.goToService')}
        </p>
      </div>
      <CalledTimer calledAt={calledAt} />
      <p style={{ fontSize: 14, fontWeight: 600 }}>{t('queue.calledWarning')}</p>
    </div>
  );
}

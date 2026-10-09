import { useTranslation } from 'react-i18next';
import type { QueueMeta } from '../../lib/useQueue';
import { useOnline } from '../../lib/useOnline';

function formatOpening(ms: number, language: string): string {
  const date = new Date(ms);
  const sameDay = date.toDateString() === new Date().toDateString();
  return date.toLocaleString(
    language,
    sameDay
      ? { hour: '2-digit', minute: '2-digit' }
      : { weekday: 'short', hour: '2-digit', minute: '2-digit' },
  );
}

export function OfflineBanner() {
  const { t } = useTranslation();
  const online = useOnline();
  if (online) return null;
  return (
    <div className="notice notice-warning" role="status">
      {t('queue.offlineBanner')}
    </div>
  );
}

export function StatusNotice({ meta }: { meta: QueueMeta | null }) {
  const { t, i18n } = useTranslation();
  if (!meta || meta.status === 'open') return null;
  const time = meta.resumeAt
    ? new Date(meta.resumeAt).toLocaleTimeString(i18n.language, {
        hour: '2-digit',
        minute: '2-digit',
      })
    : null;
  return (
    <div
      className={`notice ${meta.status === 'paused' ? 'notice-warning' : 'notice-closed'}`}
      role="status"
    >
      <strong>
        {meta.status === 'paused' ? t('queue.pausedTitle') : t('queue.closedTitle')}
      </strong>
      {meta.statusMessage && <span>{meta.statusMessage}</span>}
      {time && <span>{t('queue.returnAt', { time })}</span>}
      {meta.status === 'closed' && meta.opensAt && meta.opensAt > Date.now() && (
        <span>{t('queue.opensAt', { when: formatOpening(meta.opensAt, i18n.language) })}</span>
      )}
    </div>
  );
}

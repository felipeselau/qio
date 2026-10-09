import { useTranslation } from 'react-i18next';
import type { QueueMeta } from '../../lib/useQueue';
import NotifyOpen from '../NotifyOpen';
import { StatusNotice } from './Banners';

export function ErrorView({ onRetry }: { onRetry: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="center-col fade-in" key="error">
      <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.connectFailed')}</h1>
      <p className="muted">{t('queue.connectFailedHint')}</p>
      <button type="button" className="btn btn-primary" onClick={onRetry}>
        {t('queue.retry')}
      </button>
    </div>
  );
}

export function LoadingView() {
  const { t } = useTranslation();
  return (
    <div
      className="page fade-in"
      key="loading"
      role="status"
      aria-busy="true"
      aria-label={t('app.loading')}
    >
      <div className="page-scroll">
        <div className="skeleton skeleton-title" />
        <div className="skeleton skeleton-badge" />
        <div className="skeleton skeleton-field" />
        <div className="skeleton skeleton-field" />
        <div className="skeleton skeleton-btn" />
      </div>
    </div>
  );
}

export function GoneView() {
  const { t } = useTranslation();
  return (
    <div className="center-col fade-in" key="gone">
      <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.notFound')}</h1>
      <p className="muted">{t('queue.notFoundHint')}</p>
    </div>
  );
}

export function ClosedView({ meta, queueId }: { meta: QueueMeta | null; queueId: string }) {
  const { t } = useTranslation();
  return (
    <div className="center-col fade-in" key="closed">
      <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>{meta?.name}</h1>
      <span className="badge badge-closed">{t('queue.closedBadge')}</span>
      <StatusNotice meta={meta} />
      <p className="muted">{t('queue.closedHint')}</p>
      <NotifyOpen queueId={queueId} />
    </div>
  );
}

export function ThanksView() {
  const { t } = useTranslation();
  return (
    <div className="center-col fade-in" key="thanks">
      <div style={{ fontSize: 48 }} aria-hidden="true">🙏</div>
      <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.feedbackThanks')}</h1>
      <p className="muted">{t('queue.feedbackThanksHint')}</p>
    </div>
  );
}

export function LeftView({ onRejoin }: { onRejoin: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="center-col fade-in" key="left">
      <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.left')}</h1>
      <p className="muted">{t('queue.leftHint')}</p>
      <button type="button" className="btn btn-primary" onClick={onRejoin}>
        {t('queue.rejoin')}
      </button>
    </div>
  );
}

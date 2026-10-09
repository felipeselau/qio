import { useTranslation } from 'react-i18next';
import type { QueueMeta } from '../../lib/useQueue';
import type { PushSupport } from '../../lib/fcm';
import type { useInstallPrompt } from '../../lib/useInstallPrompt';
import { formatSlotTime } from '../../lib/slots';
import { OfflineBanner, StatusNotice } from './Banners';
import QueueLogo from './QueueLogo';

type Props = {
  meta: QueueMeta | null;
  ticket: number;
  slotStart: number | null | undefined;
  scheduled: boolean;
  claimed: boolean;
  position: number | null;
  estimatedWaitMin: number | null;
  push: PushSupport;
  pushBusy: boolean;
  onEnablePush: () => void;
  installPrompt: ReturnType<typeof useInstallPrompt>;
  confirmLeave: boolean;
  leaving: boolean;
  error: string | null;
  onAskLeave: () => void;
  onCancelLeave: () => void;
  onLeave: () => void;
};

export default function TicketView({
  meta,
  ticket,
  slotStart,
  scheduled,
  claimed,
  position,
  estimatedWaitMin,
  push,
  pushBusy,
  onEnablePush,
  installPrompt,
  confirmLeave,
  leaving,
  error,
  onAskLeave,
  onCancelLeave,
  onLeave,
}: Props) {
  const { t, i18n } = useTranslation();
  return (
    <div className="page fade-in" key="ticket">
      <div className="page-scroll">
        <OfflineBanner />
        <div className="card" style={{ textAlign: 'center', padding: 24 }}>
          <QueueLogo meta={meta} />
          <p
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: 'var(--muted)',
              letterSpacing: 1,
            }}
          >
            {t('queue.yourTicket')}
          </p>
          <p style={{ fontSize: 48, fontWeight: 800, color: 'var(--primary)' }}>
            #{ticket}
          </p>
          <p style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
            {meta?.name}
          </p>
        </div>

        {claimed && (
          <div className="notice notice-warning" role="status">
            {t('queue.claimed')}
          </div>
        )}

        {scheduled && slotStart != null && (
          <div className="card slot-time" role="status">
            {t('queue.yourSlot', { time: formatSlotTime(slotStart, i18n.language) })}
          </div>
        )}

        <div className="card" role="status" aria-live="polite">
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              marginBottom: scheduled ? 0 : 8,
            }}
          >
            <span style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
              {t('queue.position')}
            </span>
            <span style={{ fontSize: 14, fontWeight: 600 }}>
              {position != null ? (
                <span key={position} className="pop">
                  {t('queue.positionValue', { position })}
                </span>
              ) : (
                '—'
              )}
            </span>
          </div>
          {!scheduled && (
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
              }}
            >
              <span style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
                {t('queue.estimatedWait')}
              </span>
              <span style={{ fontSize: 14, fontWeight: 600 }}>
                {estimatedWaitMin != null
                  ? t('queue.estimatedWaitValue', { minutes: estimatedWaitMin })
                  : '—'}
              </span>
            </div>
          )}
        </div>

        <div
          style={{
            background: 'rgba(37, 99, 235, 0.1)',
            borderRadius: 12,
            padding: 16,
            display: 'flex',
            gap: 12,
            alignItems: 'flex-start',
          }}
        >
          <span style={{ fontSize: 20 }}>ℹ️</span>
          <p style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
            {t('queue.keepOpen')}
          </p>
        </div>

        <StatusNotice meta={meta} />

        {(push === 'ready' || push === 'unavailable') && (
          <section className="install-banner" role="region" aria-label={t('queue.pushTitle')}>
            <p>{t('queue.pushBody')}</p>
            {push === 'unavailable' && (
              <p className="muted" role="status">
                {t('queue.pushUnavailable')}
              </p>
            )}
            <div className="install-banner-actions">
              <button
                type="button"
                className="btn btn-primary"
                disabled={pushBusy}
                onClick={onEnablePush}
              >
                {t('queue.pushEnable')}
              </button>
            </div>
          </section>
        )}
        {push === 'granted' && <p className="muted push-note">{t('queue.pushOn')}</p>}
        {push === 'denied' && <p className="muted push-note">{t('queue.pushDenied')}</p>}

        {(installPrompt.canInstall || installPrompt.hint) && (
          <section className="install-banner" role="region" aria-label={t('queue.installAria')}>
            {installPrompt.canInstall ? (
              <>
                <p>{t('queue.installText')}</p>
                <div className="install-banner-actions">
                  <button
                    type="button"
                    className="btn btn-primary"
                    onClick={installPrompt.install}
                  >
                    {t('queue.install')}
                  </button>
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={installPrompt.dismiss}
                  >
                    {t('queue.notNow')}
                  </button>
                </div>
              </>
            ) : (
              <>
                <p>
                  {installPrompt.hint === 'ios'
                    ? t('queue.installIos')
                    : t('queue.installAndroid')}
                </p>
                <div className="install-banner-actions">
                  <button
                    type="button"
                    className="btn btn-secondary"
                    onClick={installPrompt.dismiss}
                  >
                    {t('queue.gotIt')}
                  </button>
                </div>
              </>
            )}
          </section>
        )}

        {confirmLeave ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <p
              style={{
                fontSize: 14,
                color: 'var(--gray-dark)',
                textAlign: 'center',
              }}
            >
              {t('queue.confirmLeaveText')}
            </p>
            <button
              type="button"
              className="btn btn-danger"
              disabled={leaving}
              onClick={onLeave}
            >
              {leaving ? t('queue.leaving') : t('queue.confirmLeave')}
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              disabled={leaving}
              onClick={onCancelLeave}
            >
              {t('queue.cancel')}
            </button>
          </div>
        ) : (
          <button type="button" className="btn btn-danger-ghost" onClick={onAskLeave}>
            {t('queue.leave')}
          </button>
        )}
        {error && <p className="error-text" role="alert">{error}</p>}
      </div>
    </div>
  );
}

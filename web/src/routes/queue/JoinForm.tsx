import type { FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import type { QueueMeta } from '../../lib/useQueue';
import { formatPhone } from '../../lib/format';
import type { SlotOption } from '../../lib/slots';
import NotifyOpen from '../NotifyOpen';
import { OfflineBanner, StatusNotice } from './Banners';
import QueueLogo from './QueueLogo';

type Props = {
  queueId: string;
  meta: QueueMeta | null;
  full: boolean;
  scheduled: boolean;
  publicReady: boolean;
  waitSummary: string;
  slotOptions: SlotOption[];
  slotId: string | null;
  selectedUnavailable: boolean;
  name: string;
  phone: string;
  submitting: boolean;
  error: string | null;
  onName: (value: string) => void;
  onPhone: (value: string) => void;
  onSlot: (id: string) => void;
  onSubmit: (e: FormEvent) => void;
};

export default function JoinForm({
  queueId,
  meta,
  full,
  scheduled,
  publicReady,
  waitSummary,
  slotOptions,
  slotId,
  selectedUnavailable,
  name,
  phone,
  submitting,
  error,
  onName,
  onPhone,
  onSlot,
  onSubmit,
}: Props) {
  const { t } = useTranslation();
  return (
    <div className="page fade-in" key="join">
      <div className="page-scroll">
        <OfflineBanner />
        <div style={{ textAlign: 'center', marginBottom: 8 }}>
          <QueueLogo meta={meta} />
          <h1 data-autofocus tabIndex={-1} style={{ fontSize: 24, fontWeight: 700 }}>{meta?.name}</h1>
          <span
            className={`badge badge-${meta?.status ?? 'open'}`}
            style={{ marginTop: 8 }}
          >
            {meta?.status === 'paused'
              ? t('queue.statusPaused')
              : meta?.status === 'closed'
                ? t('queue.statusClosed')
                : t('queue.statusOpen')}
          </span>
        </div>

        {meta?.description && (
          <p style={{ fontSize: 14, color: 'var(--gray-dark)', textAlign: 'center' }}>
            {meta.description}
          </p>
        )}

        <StatusNotice meta={meta} />

        {full && meta?.status === 'open' && (
          <div className="notice notice-warning" role="status">
            <strong>{t('queue.fullTitle')}</strong>
            <span>{t('queue.fullHint')}</span>
          </div>
        )}

        {!scheduled && meta?.status !== 'closed' && publicReady && (
          <p className="wait-summary">{waitSummary}</p>
        )}

        {meta?.status === 'paused' ? (
          <>
            <p className="muted" style={{ textAlign: 'center' }}>
              {t('queue.pausedNoJoin')}
            </p>
            <NotifyOpen queueId={queueId} />
          </>
        ) : (
          <form
            onSubmit={onSubmit}
            style={{ display: 'flex', flexDirection: 'column', gap: 16 }}
          >
            <div className="field">
              <label htmlFor="name">{t('queue.nameLabel')}</label>
              <input
                id="name"
                type="text"
                value={name}
                onChange={(e) => onName(e.target.value)}
                placeholder={t('queue.namePlaceholder')}
                autoComplete="name"
                maxLength={60}
                aria-describedby="privacy-notice"
              />
            </div>
            <div className="field">
              <label htmlFor="phone">{t('queue.phoneLabel')}</label>
              <input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => onPhone(formatPhone(e.target.value))}
                placeholder="(00) 00000-0000"
                autoComplete="tel"
                aria-describedby="privacy-notice"
              />
              <p id="privacy-notice" className="field-hint">
                {t('queue.privacyNotice')}{' '}
                <a href="/privacidade" target="_blank" rel="noopener noreferrer">
                  {t('queue.privacyLink')}
                </a>
              </p>
            </div>
            {scheduled && (
              <fieldset className="slot-picker">
                <legend>{t('queue.slotTitle')}</legend>
                <div className="slot-list" role="radiogroup" aria-label={t('queue.slotTitle')}>
                  {slotOptions.map(({ slot, free, past, slotFull }) => {
                    const unavailable = past || slotFull;
                    return (
                      <label
                        key={slot.id}
                        className={`slot-option${slotId === slot.id ? ' slot-option-on' : ''}${
                          unavailable ? ' slot-option-off' : ''
                        }`}
                      >
                        <input
                          type="radio"
                          name="slot"
                          value={slot.id}
                          checked={slotId === slot.id}
                          disabled={unavailable}
                          onChange={() => onSlot(slot.id)}
                        />
                        <span className="slot-option-time">{slot.start}</span>
                        <span className="slot-option-info">
                          {past
                            ? t('queue.slotPast')
                            : slotFull
                              ? t('queue.slotFull')
                              : t('queue.slotSpots', { count: free })}
                        </span>
                      </label>
                    );
                  })}
                </div>
              </fieldset>
            )}
            {error && <p className="error-text" role="alert">{error}</p>}
            <button
              type="submit"
              className="btn btn-primary"
              disabled={
                submitting ||
                meta?.status !== 'open' ||
                full ||
                (scheduled && (!slotId || selectedUnavailable))
              }
            >
              {submitting ? t('queue.joining') : t('queue.join')}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}

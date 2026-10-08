import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { onAuthStateChanged, signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';
import {
  getStoredEntryId,
  clearStoredEntryId,
  getPendingFeedback,
  storePendingFeedback,
  clearPendingFeedback,
} from '../lib/storage';
import { joinQueue, leaveQueue, saveFcmToken, submitFeedback } from '../lib/join';
import {
  getFcmToken,
  listenForMessages,
  pushSupport,
  requestPushPermission,
  type PushSupport,
} from '../lib/fcm';
import { useQueue, type QueueMeta } from '../lib/useQueue';
import {
  elapsedSince,
  formatElapsed,
  formatPhone,
  isValidPhone,
  waitRange,
} from '../lib/format';
import { playAlertSound, unlockAudio } from '../lib/alert';
import { holdWakeLock } from '../lib/wakeLock';
import { useOnline } from '../lib/useOnline';
import { useInstallPrompt } from '../lib/useInstallPrompt';
import { formatSlotTime, isSlotFull, isSlotPast, slotTaken } from '../lib/slots';

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

function QueueLogo({ meta }: { meta: QueueMeta | null }) {
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

function OfflineBanner() {
  const { t } = useTranslation();
  const online = useOnline();
  if (online) return null;
  return (
    <div className="notice notice-warning" role="status">
      {t('queue.offlineBanner')}
    </div>
  );
}

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

function StatusNotice({ meta }: { meta: QueueMeta | null }) {
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

type Phase =
  | 'loading'
  | 'join'
  | 'ticket'
  | 'called'
  | 'left'
  | 'closed'
  | 'gone'
  | 'feedback'
  | 'thanks';

const MAX_COMMENT = 300;

export default function QueuePage() {
  const { t, i18n } = useTranslation();
  const { queueId = '' } = useParams();
  const [slotId, setSlotId] = useState<string | null>(null);
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30000);
    return () => window.clearInterval(timer);
  }, []);
  const [authed, setAuthed] = useState(false);
  const [entryId, setEntryId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [hasLeft, setHasLeft] = useState(false);
  const [fcmDone, setFcmDone] = useState(false);
  const installPrompt = useInstallPrompt();
  const [feedbackId, setFeedbackId] = useState<string | null>(() => getPendingFeedback(queueId));
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [sendingFeedback, setSendingFeedback] = useState(false);
  const [thanked, setThanked] = useState(false);

  const {
    meta,
    myEntry,
    myEntryResolved,
    position,
    estimatedWaitMin,
    waitingCount,
    avgServiceMin,
    publicTickets,
    full,
    loading,
    exists,
    failed,
    retry,
  } = useQueue(queueId, entryId, authed);

  const scheduled = meta?.mode === 'schedule';
  const slotOptions = (meta?.slots ?? []).map((slot) => {
    const taken = slotTaken(publicTickets, slot);
    const past = isSlotPast(slot.start, now);
    const slotFull = isSlotFull(taken, slot);
    return { slot, free: Math.max(slot.capacity - taken, 0), past, slotFull };
  });
  const selectedOption = slotOptions.find((o) => o.slot.id === slotId);
  const selectedUnavailable = !!selectedOption && (selectedOption.past || selectedOption.slotFull);

  const brandColor = meta?.brandColor ?? null;
  useEffect(() => {
    const root = document.documentElement;
    if (brandColor) root.style.setProperty('--brand', brandColor);
    else root.style.removeProperty('--brand');
    return () => {
      root.style.removeProperty('--brand');
    };
  }, [brandColor]);

  const queueName = meta?.name ?? null;
  useEffect(() => {
    if (!queueName) return;
    const previous = document.title;
    document.title = `${queueName} · Qio`;
    return () => {
      document.title = previous;
    };
  }, [queueName]);

  const range = waitRange(waitingCount + 1, avgServiceMin);
  const waitSummary =
    waitingCount === 0 || !range
      ? t('queue.noQueueNow')
      : t('queue.aheadSummary', { count: waitingCount, min: range.min, max: range.max });

  const [authFailed, setAuthFailed] = useState(false);
  const [authAttempt, setAuthAttempt] = useState(0);
  function handleRetry() {
    setAuthFailed(false);
    setAuthAttempt((n) => n + 1);
    retry();
  }
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      if (user) {
        setAuthed(true);
        setAuthFailed(false);
        setEntryId(getStoredEntryId(queueId));
      } else {
        signInAnonymously(auth).catch(() => setAuthFailed(true));
      }
    });
    return unsub;
  }, [queueId, authAttempt]);

  // limpa entryId local se a entry sumiu do RTDB (served/no_show/left).
  // myEntryResolved garante que o listener já entregou o primeiro valor —
  // sem isso, o gap entre setEntryId e o primeiro onValue limparia a entry
  // recém-criada (bug: permitia re-entrar na fila infinitamente).
  useEffect(() => {
    if (entryId && myEntry === null && myEntryResolved && !loading && authed) {
      const had = getStoredEntryId(queueId);
      if (had === entryId) {
        clearStoredEntryId(queueId);
        setEntryId(null);
      }
    }
  }, [myEntry, myEntryResolved, entryId, loading, authed, queueId]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    unlockAudio();
    if (!name.trim()) {
      setError(t('errors.nameRequired'));
      return;
    }
    if (phone.trim() && !isValidPhone(phone.trim())) {
      setError(t('errors.phoneInvalid'));
      return;
    }
    if (scheduled && (!slotId || selectedUnavailable)) {
      setError(t('queue.slotRequired'));
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result = await joinQueue(
        queueId,
        name.trim(),
        phone.trim(),
        scheduled ? slotId : null,
      );
      setEntryId(result.entryId);
    } catch (err: any) {
      setError(err?.message ?? t('errors.joinFailed'));
    } finally {
      setSubmitting(false);
    }
  }

  async function handleLeave() {
    if (!entryId) return;
    setLeaving(true);
    setError(null);
    try {
      await leaveQueue(queueId, entryId);
      setHasLeft(true);
      setConfirmLeave(false);
    } catch (err: any) {
      setError(err?.message ?? t('errors.leaveFailed'));
      setLeaving(false);
    }
  }

  function handleRejoin() {
    clearStoredEntryId(queueId);
    setEntryId(null);
    setHasLeft(false);
    setLeaving(false);
    setConfirmLeave(false);
    setError(null);
  }

  function playAlert() {
    playAlertSound();
    if (navigator.vibrate) navigator.vibrate([400, 200, 400]);
  }

  const phase: Phase = (() => {
    if (loading || !authed || failed) return 'loading';
    if (!exists) return 'gone';
    if (hasLeft) return 'left';
    if (meta?.status === 'closed' && !myEntry) return 'closed';
    if (!myEntry && thanked) return 'thanks';
    if (!myEntry && feedbackId) return 'feedback';
    if (!myEntry) return 'join';
    if (myEntry.status === 'called') {
      // dispara alerta uma vez ao entrar no estado
      return 'called';
    }
    if (myEntry.status === 'left') return 'left';
    return 'ticket';
  })();

  const recalledAt = myEntry?.recalledAt ?? null;
  const lastRecall = useRef<number | null>(null);
  useEffect(() => {
    if (phase !== 'called') {
      lastRecall.current = recalledAt;
      return;
    }
    if (recalledAt && lastRecall.current !== recalledAt) {
      playAlert();
    }
    lastRecall.current = recalledAt;
  }, [phase, recalledAt]);

  // dispara som/vibração quando entra em 'called'
  const [alerted, setAlerted] = useState(false);
  useEffect(() => {
    if (phase === 'called' && !alerted) {
      playAlert();
      setAlerted(true);
    }
    if (phase !== 'called') setAlerted(false);
  }, [phase, alerted]);

  useEffect(() => {
    if (phase === 'called' && entryId) {
      storePendingFeedback(queueId, entryId);
      setFeedbackId(entryId);
    }
  }, [phase, entryId, queueId]);

  async function handleFeedbackSend() {
    if (!feedbackId || rating < 1) return;
    setSendingFeedback(true);
    setError(null);
    try {
      await submitFeedback(queueId, feedbackId, rating, comment.trim());
      clearPendingFeedback(queueId);
      setFeedbackId(null);
      setThanked(true);
    } catch (err: any) {
      setError(err?.message ?? t('errors.feedbackFailed'));
    } finally {
      setSendingFeedback(false);
    }
  }

  function handleFeedbackSkip() {
    clearPendingFeedback(queueId);
    setFeedbackId(null);
    setError(null);
  }

  const [push, setPush] = useState<PushSupport>('unsupported');
  const [pushBusy, setPushBusy] = useState(false);

  const registerToken = useCallback(() => {
    if (!entryId) return;
    getFcmToken().then((token) => {
      if (token) saveFcmToken(queueId, entryId, token).catch(() => {});
    });
  }, [entryId, queueId]);

  useEffect(() => {
    if (phase !== 'ticket' || !myEntry || !entryId || fcmDone) return;
    setFcmDone(true);
    pushSupport().then((state) => {
      setPush(state);
      if (state === 'granted') registerToken();
    });
  }, [phase, myEntry, entryId, fcmDone, registerToken]);

  useEffect(() => {
    if (phase !== 'ticket') return;
    const release = holdWakeLock();
    const unlock = () => unlockAudio();
    window.addEventListener('pointerdown', unlock, { once: true });
    window.addEventListener('keydown', unlock, { once: true });
    return () => {
      release();
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
  }, [phase]);

  async function enablePush() {
    unlockAudio();
    setPushBusy(true);
    try {
      const result = await requestPushPermission();
      setPush(result);
      if (result === 'granted') registerToken();
    } finally {
      setPushBusy(false);
    }
  }

  // notificação foreground (page oculta) — RTDB já cuida do estado em tela
  useEffect(() => {
    return listenForMessages(() => {});
  }, []);

  if (phase === 'loading') {
    if (authFailed || failed) {
      return (
        <div className="center-col fade-in" key="error">
          <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.connectFailed')}</h1>
          <p className="muted">{t('queue.connectFailedHint')}</p>
          <button type="button" className="btn btn-primary" onClick={handleRetry}>
            {t('queue.retry')}
          </button>
        </div>
      );
    }
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

  if (phase === 'gone') {
    return (
      <div className="center-col fade-in" key="gone">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.notFound')}</h1>
        <p className="muted">{t('queue.notFoundHint')}</p>
      </div>
    );
  }

  if (phase === 'closed') {
    return (
      <div className="center-col fade-in" key="closed">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{meta?.name}</h1>
        <span className="badge badge-closed">{t('queue.closedBadge')}</span>
        <StatusNotice meta={meta} />
        <p className="muted">{t('queue.closedHint')}</p>
      </div>
    );
  }

  if (phase === 'called' && myEntry) {
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
        <div
          role="alert"
          style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}
        >
          <div style={{ fontSize: 72 }} aria-hidden="true">✓</div>
          <h1 style={{ fontSize: 24, fontWeight: 700 }}>{t('queue.yourTurn')}</h1>
          {meta?.name && <p style={{ fontSize: 16, opacity: 0.95 }}>{meta.name}</p>}
          <p style={{ fontSize: 18, fontWeight: 600 }}>
            {t('queue.ticketNumber', { ticket: myEntry.ticket })}
          </p>
          <p style={{ fontSize: 14, opacity: 0.9 }}>
            {t('queue.goToService')}
          </p>
        </div>
        <CalledTimer calledAt={myEntry.calledAt} />
        <p style={{ fontSize: 14, fontWeight: 600 }}>{t('queue.calledWarning')}</p>
      </div>
    );
  }

  if (phase === 'thanks') {
    return (
      <div className="center-col fade-in" key="thanks">
        <div style={{ fontSize: 48 }}>🙏</div>
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.feedbackThanks')}</h1>
        <p className="muted">{t('queue.feedbackThanksHint')}</p>
      </div>
    );
  }

  if (phase === 'feedback') {
    return (
      <div className="page fade-in" key="feedback">
        <div className="page-scroll">
          <div className="card" style={{ textAlign: 'center' }}>
            <h1 style={{ fontSize: 20, fontWeight: 700, marginBottom: 12 }}>
              {t('queue.feedbackTitle')}
            </h1>
            <div className="stars" role="radiogroup" aria-label={t('queue.feedbackTitle')}>
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  type="button"
                  role="radio"
                  aria-checked={rating === n}
                  aria-label={t('queue.feedbackStar', { count: n })}
                  className={`star${n <= rating ? ' star-on' : ''}`}
                  onClick={() => setRating(n)}
                >
                  ★
                </button>
              ))}
            </div>
            <div className="field" style={{ marginTop: 16, textAlign: 'left' }}>
              <label htmlFor="feedback-comment">{t('queue.feedbackComment')}</label>
              <textarea
                id="feedback-comment"
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                maxLength={MAX_COMMENT}
                rows={3}
              />
            </div>
          </div>
          {error && <p className="error-text" role="alert">{error}</p>}
          <button
            type="button"
            className="btn btn-primary"
            disabled={rating < 1 || sendingFeedback}
            onClick={handleFeedbackSend}
          >
            {sendingFeedback ? t('queue.feedbackSending') : t('queue.feedbackSend')}
          </button>
          <button
            type="button"
            className="btn btn-danger-ghost"
            disabled={sendingFeedback}
            onClick={handleFeedbackSkip}
          >
            {t('queue.feedbackSkip')}
          </button>
        </div>
      </div>
    );
  }

  if (phase === 'left') {
    return (
      <div className="center-col fade-in" key="left">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.left')}</h1>
        <p className="muted">{t('queue.leftHint')}</p>
        <button type="button" className="btn btn-primary" onClick={handleRejoin}>
          {t('queue.rejoin')}
        </button>
      </div>
    );
  }

  if (phase === 'ticket' && myEntry) {
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
              #{myEntry.ticket}
            </p>
            <p style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
              {meta?.name}
            </p>
          </div>

          {scheduled && myEntry.slotStart != null && (
            <div className="card slot-time" role="status">
              {t('queue.yourSlot', { time: formatSlotTime(myEntry.slotStart, i18n.language) })}
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

          {push === 'ready' && (
            <section className="install-banner" role="region" aria-label={t('queue.pushTitle')}>
              <p>{t('queue.pushBody')}</p>
              <div className="install-banner-actions">
                <button
                  type="button"
                  className="btn btn-primary"
                  disabled={pushBusy}
                  onClick={enablePush}
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
                onClick={handleLeave}
              >
                {leaving ? t('queue.leaving') : t('queue.confirmLeave')}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                disabled={leaving}
                onClick={() => setConfirmLeave(false)}
              >
                {t('queue.cancel')}
              </button>
            </div>
          ) : (
            <button
              type="button"
              className="btn btn-danger-ghost"
              onClick={() => setConfirmLeave(true)}
            >
              {t('queue.leave')}
            </button>
          )}
          {error && <p className="error-text" role="alert">{error}</p>}
        </div>
      </div>
    );
  }

  // phase === 'join'
  return (
    <div className="page fade-in" key="join">
      <div className="page-scroll">
        <OfflineBanner />
        <div style={{ textAlign: 'center', marginBottom: 8 }}>
          <QueueLogo meta={meta} />
          <h1 style={{ fontSize: 24, fontWeight: 700 }}>{meta?.name}</h1>
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

        {!scheduled && meta?.status !== 'closed' && (
          <p className="wait-summary" role="status" aria-live="polite">
            {waitSummary}
          </p>
        )}

        {meta?.status === 'paused' ? (
          <p className="muted" style={{ textAlign: 'center' }}>
            {t('queue.pausedNoJoin')}
          </p>
        ) : (
        <form
          onSubmit={handleSubmit}
          style={{ display: 'flex', flexDirection: 'column', gap: 16 }}
        >
          <div className="field">
            <label htmlFor="name">{t('queue.nameLabel')}</label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t('queue.namePlaceholder')}
              autoComplete="name"
              maxLength={60}
            />
          </div>
          <div className="field">
            <label htmlFor="phone">{t('queue.phoneLabel')}</label>
            <input
              id="phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(formatPhone(e.target.value))}
              placeholder="(00) 00000-0000"
              autoComplete="tel"
            />
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
                        onChange={() => setSlotId(slot.id)}
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